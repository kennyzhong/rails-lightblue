# -*- coding: utf-8 -*-

class ClientVersion < ActiveRecord::Base
  has_one :job, :class_name => "JenkinsJob", :foreign_key =>:id, :primary_key => :job_name
end

