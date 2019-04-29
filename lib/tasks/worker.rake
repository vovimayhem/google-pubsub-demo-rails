namespace :worker do
  # [START run_worker]
  desc "Run task queue worker"
  task start: :environment do
    ActiveJob::QueueAdapters::PubSubQueueAdapter.run_worker!
  end
  # [END run_worker]
end
