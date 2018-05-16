class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument,
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
