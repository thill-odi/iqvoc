require 'test_helper'
require 'capybara/envjs'

class ClientEditConceptsTest < ActionDispatch::IntegrationTest

  setup do
    @concept = Iqvoc::Concept.base_class.create(:origin => "_666",
        :published_at => Time.now)

    # create a user
    password = "FooBar"
    @admin = User.create(:forename => "John", :surname => "Doe",
        :email => "foo@example.org",
        :password => password, :password_confirmation => password,
        :active => true, :role => "administrator")
    @admin.password = password # required because password is only saved in encrypted form

    Capybara.current_driver = :envjs
  end

  teardown do
    Capybara.use_default_driver
  end

  test "dynamic addition of notes" do
    # login
    visit new_user_session_path(:lang => :de)
    fill_in "E-Mail", :with => @admin.email
    fill_in "Passwort", :with => @admin.password
    click_button "Anmelden"
    assert page.has_no_css?(".flash_error")
    assert page.has_content?("Anmeldung erfolgreich")
    # concept edit view
    visit concept_path(@concept, :lang => "de", :format => "html")
    click_link_or_button("Neue Version erstellen")
    assert page.has_css?("#concept_edit")

    section = page.find("#label_note_skos_definitions_data")
    assert page.has_css?(".note_relation", :count => Iqvoc::Concept.note_class_names.length)
    assert page.has_css?("#label_note_skos_definitions_data", :count => 1)
    assert section.has_css?("li", :count => 1)

    # unhide default note input
    section.click_link_or_button("Weitere hinzufügen")
    assert section.has_css?("li", :count => 1)

    # add another note input
    section.click_link_or_button("Weitere hinzufügen")
    assert section.has_css?("li", :count => 2)

    # add some note text
    section.fill_in "concept_note_skos_definitions_attributes_0_value",
        :with => "lorem ipsum\ndolor sit amet"
    section.fill_in "concept_note_skos_definitions_attributes_1_value",
        :with => "consectetur adipisicing elit"

    assert section.all("textarea")[0].value == "lorem ipsum\ndolor sit amet"
    assert section.all("textarea")[1].value == "consectetur adipisicing elit"

    # save concept
    page.click_link_or_button("Speichern")
    assert page.has_content?("Konzept wurde erfolgreich aktualisiert.")
    # return to edit mode
    page.click_link_or_button("Bearbeitung fortsetzen")
    assert page.has_css?("#concept_edit")

    section = page.find("#label_note_skos_definitions_data")

    assert section.has_css?("li", :count => 2)
    assert section.has_css?("[type=checkbox]", :count => 2)
    assert section.has_no_css?("li.deleted")

    # mark note for deletion
    section.check("Löschen")
    section.find("[type=checkbox]").trigger("change") # apparently `check` doesn't do this automatically
    assert section.has_css?("li.deleted", :count => 1)
  end

end
