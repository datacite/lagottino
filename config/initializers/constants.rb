class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        NoMethodError,
                        ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument,
                        Elasticsearch::Transport::Transport::Errors::NotFound,
                        JSON::ParserError,
                        JWT::VerificationError,
                        JSON::ParserError,
                        Nokogiri::XML::SyntaxError,
                        ActiveRecord::RecordNotFound,
                        ActiveRecord::RecordNotUnique,
                        AbstractController::ActionNotFound,
                        ActionController::UnknownFormat,
                        ActionController::RoutingError,
                        ActionController::ParameterMissing,
                        ActionController::UnpermittedParameters]
