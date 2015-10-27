RESCUABLE_EXCEPTIONS = [ActiveRecord::RecordNotFound,
                        CanCan::AccessDenied,
                        ActionController::ParameterMissing,
                        ActiveModel::ForbiddenAttributesError,
                        NoMethodError]
