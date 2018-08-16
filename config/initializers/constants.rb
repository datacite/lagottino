class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        NoMethodError,
                        JSON::ParserError,
                        JWT::VerificationError,
                        ActiveRecord::RecordNotFound,
                        ActiveRecord::RecordNotUnique,
                        AbstractController::ActionNotFound,
                        ActionController::UnknownFormat,
                        ActionController::RoutingError,
                        ActionController::ParameterMissing,
                        ActionController::UnpermittedParameters]
