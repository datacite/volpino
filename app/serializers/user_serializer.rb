class UserSerializer < ActiveModel::Serializer
  cache key: 'user'
  attributes :given_names, :family_name, :credit_name, :ORCID
  has_many :works

  def ORCID
    object.orcid
  end

  def id
    object.orcid
  end

  def works
    object.claims
  end

  class ClaimSerializer < ActiveModel::Serializer
    attributes :source_id, :state, :claimed_at

    def id
      "http://doi.org/#{object.doi}"
    end

    def type
      "works"
    end

    def claimed_at
      object.claimed_at.iso8601
    end

    def state
      object.human_state_name
    end
  end
end
