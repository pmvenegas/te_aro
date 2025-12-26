# Te Aro ActiveRecordObserver

This tool is intended to help understand how a particular block of code changes `ActiveRecord` objects and/or database records. It allows you to see what objects and fields are created and changed, and which database changes are persisted.

Note that this assumes standard `created_at` and `updated_at` fields are present.

## Installation

_NB: This is for including the tool as a local gem for now, as it has not yet been published._

Add this line to your application's Gemfile:

```ruby
gem 'te_aro', path: 'path/to/te_aro'
```

And then execute:

    $ bundle

## Usage

```ruby
# With defaults:
TeAro::Observer.new.observe { @some_ar_object.do_something_that_triggers_callbacks }

# Can also use the Kernel#aro method to call with defaults:
aro { @some_ar_object.do_something }
```

## Sample Session

Te Aro in action on GitLab code:

```ruby
# gitlab-development-kit/gitlab/spec/services/merge_requests/create_service_spec.rb
      # ...
      before do
        project.team << [user, :master]
        project.team << [assignee, :developer]
        allow(service).to receive(:execute_hooks)

        aro { @merge_request = service.execute }
      end
      # ...
```

Run:
```
$ bundle exec rspec spec/services/merge_requests/create_service_spec.rb -fd
```

Output in `log/te_aro.log`:
```
Object Count Changes:
        GitlabIssueTrackerService: +1
        MergeRequest: +1
        MergeRequestDiff: +1
New ActiveRecord objects:
        GitlabIssueTrackerService (id=1)
                id: 1
                type: GitlabIssueTrackerService
                project_id: 1
                created_at: 2016-03-21 07:17:46 UTC
                updated_at: 2016-03-21 07:17:46 UTC
                active: false
                properties: {}
                template: false
                push_events: true
                issues_events: true
                merge_requests_events: true
                tag_push_events: true
                note_events: true
                build_events: true
                category: issue_tracker
                default: true
        MergeRequest (id=1)
                id: 1
                target_branch: master
                source_branch: feature
                source_project_id: 1
                author_id: 3
                title: Awesome merge_request
                created_at: 2016-03-21 07:17:46 UTC
                updated_at: 2016-03-21 07:17:46 UTC
                state: opened
                merge_status: unchecked
                target_project_id: 1
                iid: 1
                description: please fix
                position: 0
                merge_params: {}
                merge_when_build_succeeds: false
        MergeRequestDiff (id=1)
                id: 1
                state: collected
                st_commits: [{:id=>"0b4bc9a49b562e85de7cc9e834518ea6828729b9", :message=>"Feature added\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n", :parent_ids=>["ae73cb07c9eeaf35924a10f713b364d32b2dd34f"], :authored_date=>2014-02-27 21:26:01 +1300, :author_name=>"Dmitriy Zaporozhets", :author_email=>"dmitriy.zaporozhets@gmail.com", :committed_date=>2014-02-27 21:26:01 +1300, :committer_name=>"Dmitriy Zaporozhets", :committer_email=>"dmitriy.zaporozhets@gmail.com"}]
                st_diffs: [{:diff=>"--- /dev/null\n+++ b/files/ruby/feature.rb\n@@ -0,0 +1,5 @@\n+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end\n", :new_path=>"files/ruby/feature.rb", :old_path=>"files/ruby/feature.rb", :a_mode=>"0", :b_mode=>"100644", :new_file=>true, :renamed_file=>false, :deleted_file=>false, :too_large=>false}]
                merge_request_id: 1
                created_at: 2016-03-21 07:17:46 UTC
                updated_at: 2016-03-21 07:17:46 UTC
                base_commit_sha: ae73cb07c9eeaf35924a10f713b364d32b2dd34f
                real_size: 1
Changed and persisted ActiveRecord objects:
        Project (id=1)
                last_activity_at: 2016-03-21 07:17:45 UTC -> 2016-03-21 07:17:46 UTC
```

### Output

By default, output is logged to `log/te_aro.log`. This can be changed by passing a `Logger` instance when constructing the observer.

Eg to log to STDOUT:
```ruby
TeAro::Observer.new(logger: Logger.new(STDOUT)).observe { some_ar_object.do_something }
```


### Options

Options are passed as a hash to `Observer.new`.

The following options are available:

* `:targets` Sets a whitelist of specific `ActiveRecord` subclasses to observe. Defaults to `ActiveRecord`, i.e. all subclasses.
* `:logger` Sets a custom logger to record output.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pmvenegas/te_aro.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
