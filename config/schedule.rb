# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
every 2.minutes do
	rake "export_products_db:to_csv"
end
#
every 1.days do
	rake "export_products_db:to_csv"
end

# Learn more: http://github.com/javan/whenever
