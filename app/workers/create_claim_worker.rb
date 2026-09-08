class CreateClaimWorker
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV['RAILS_ENV']}_volpino" }, auto_delete: true

  def perform(sqs_msg, data)
    data = JSON.parse(data)

    orcid = data["orcid"]
    doi = data["doi"]
    source_id = data["source_id"]
    claim_action = data["claim_action"]

    ActiveRecord::Base.connection_pool.with_connection do
      return if orcid.blank? || doi.blank?

      User.find_or_create_by(uid: orcid)

      @claim = Claim.where(orcid: orcid, doi: doi).first
      exists = @claim.present?

      if exists
        @claim.assign_attributes(
          source_id: source_id,
          claim_action: claim_action,
          aasm_state: "waiting"
        )
      else
        @claim = Claim.new(
          orcid: orcid,
          doi: doi,
          source_id: source_id,
          claim_action: claim_action
        )
      end

      if @claim.save
        @claim.queue_claim_job
      else
        Rails.logger.error "[CreateClaim] Failed to create claim for #{orcid} – #{doi}: #{@claim.errors.inspect}"
      end
    end
  end
end
