require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment groups" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should create an assignment group" do
    get "/courses/#{@course.id}/assignments"

    wait_for_animations
    driver.find_element(:css, '#right-side .add_group_link').click
    driver.find_element(:id, 'assignment_group_name').send_keys('test group')
    driver.find_element(:id, 'add_group_form').submit
    wait_for_animations
    driver.find_element(:id, 'add_group_form').should_not be_displayed
    driver.find_element(:css, '#groups .assignment_group').should include_text('test group')
  end


  it "should edit group details" do
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)
    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    driver.find_element(:css, '.edit_group_link img').click
    #set number of lowest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    driver.find_element(:css, 'input.drop_count').send_keys('2')
    #set number of highest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    click_option('.form_rules div:nth-child(2) select', 'Drop the Highest')
    driver.find_element(:css, '.form_rules div:nth-child(2) input').send_keys('3')
    #set assignment to never drop
    driver.find_element(:css, '.add_rule_link').click
    never_drop_css = '.form_rules div:nth-child(3) select'
    click_option(never_drop_css, 'Never Drop')
    wait_for_animations
    assignment_css = '.form_rules div:nth-child(3) .never_drop_assignment select'
    keep_trying_until { driver.find_element(:css, assignment_css).displayed? }
    click_option(assignment_css, assignment.title)
    #delete second grading rule and save
    driver.find_element(:css, '.form_rules div:nth-child(2) a img').click
    driver.find_element(:css, '#add_group_form button[type="submit"]').click

    #verify grading rules
    driver.find_element(:css, '.more_info_link').click
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('2')
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('assignment with rubric')
  end

  it "should edit assignment group's grade weights" do
    @course.assignment_groups.create!(:name => "first group")
    @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"

    driver.find_element(:id, 'class_weighting_policy').click
    #wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    driver.find_element(:css, 'input.weight').clear
    #need to wait for the total to update
    wait_for_animations
    keep_trying_until { find_with_jquery('#group_weight_total').text.should == '50%' }
  end
end
