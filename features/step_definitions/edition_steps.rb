include GdsApi::TestHelpers::Panopticon

# Convert business-ness to a Boolean flag
Transform /^for business $/ do |business|
  true
end

Given /I am signed in to Publisher/ do
  FactoryGirl.create(:user, :name => 'Example User', :email => 'test@gov.uk', :version => 1, :uid => 't3st1ng')
end

Given /(.*?) editions (for business )?exist in Publisher/ do |state, business|
  @editions = FactoryGirl.create_list(
    :edition,
    10,
    :state => format_state(state),
    :business_proposition => business || false
  )
end

Given /I have an artefact in Panopticon/ do
  tag = FactoryGirl.create(:tag, tag_id: "example-content", tag_type: "section", title: "Example content")
  artefact = FactoryGirl.create(:artefact, "name" => "Test", "slug" => "test", "kind" => "answer", "department" => "GDS", "primary_section" => "example-content", "owning_app" => "publisher")
  @panopticon_id = artefact.id
end

And /I have clicked the create publication button in Panopticon/ do
  # nothing
end

When /I am redirected to Publisher/ do
  visit admin_publication_path(@panopticon_id)
end

Then /a new edition should be created/ do
  @edition = AnswerEdition.where(:panopticon_id => @panopticon_id).first
  assert @edition.present?
end

When /I visit the editions list/ do
  visit admin_root_path
end

When /filter by everyone/ do
  select "All", :from => 'user_filter'
  click_button "Filter"
end

When /select the (.*) tab/ do |state|
  # TODO: Actually make the AJAX tab loading work on the list page

  visit admin_root_path(:list => format_state(state) )
end

Then /I should see each (.*) edition in the list/ do |state|
  check_editions_appear_in_list @editions
end

Then /each edition should (not )?be marked as a business edition/ do |negate|
  business = negate.nil?
  check_editions_appear_in_list @editions, :business => business
end

When /I update fields for an edition/ do
  @edition = @editions.sample
  visit admin_edition_path(@edition)
  update_edition_fields @edition
end

Then /the edition form should show the fields/ do
  check_edition_form_appears_for @edition
  check_form_values_appear_for @edition
end