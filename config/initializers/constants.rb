# Networking constants
DEFAULT_TIMEOUT = 60
NETWORKABLE_EXCEPTIONS = [Faraday::Error::ClientError,
                          Faraday::ConnectionFailed,
                          URI::InvalidURIError,
                          Encoding::UndefinedConversionError,
                          ArgumentError,
                          NoMethodError,
                          TypeError]

RESCUABLE_EXCEPTIONS = [ActiveRecord::RecordNotFound,
                        CanCan::AccessDenied,
                        JWT::VerificationError,
                        ActionController::ParameterMissing,
                        ActiveModel::ForbiddenAttributesError,
                        NoMethodError]

# Format used for DOI validation
# The prefix is 10.x where x is 4-5 digits. The suffix can be anything, but can"t be left off
DOI_FORMAT = %r(\A10\.\d{4,5}/.+)

# Format used for URL validation
URL_FORMAT = %r(\A(http|https|ftp):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z)

# Form queue options
QUEUE_OPTIONS = ["high", "default", "low"]
