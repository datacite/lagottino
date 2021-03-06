class UniquenessValidator < ActiveModel::Validator
  def validate(record)
    result = record.class.find_by_id(record.id)
    record.errors.add(:symbol, "This ID has already been taken") if result.present?
  end
end