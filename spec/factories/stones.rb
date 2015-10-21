FactoryGirl.define do
  factory :stone do
    name "ストーン１"
    stone_type "サンプル１"
    description "説明１"
    parent_id ""
    association :place, factory: :place
    association :box, factory: :box
    association :physical_form, factory: :physical_form
    association :classification, factory: :classification
    quantity 1
    quantity_unit "数量単位１"
    sequence(:igsn) { |n| "%09d" % "#{n}" }
    age_min 1
    age_max 10
    age_unit "a"
    size "111"
    size_unit "k"
  end
end
