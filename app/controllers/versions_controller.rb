require 'xmlsimple'

class VersionsController < ApplicationController
  def index
    tag = params[:tag]
    @current_tag = :ios
    @tags = [:ios, :android]
    if nil != tag and not tag.empty? then
      if @tags.include?(tag.to_sym) then
        @current_tag = tag.to_sym
      end
    else
      if request.env['HTTP_USER_AGENT'].downcase.match(/android/)
        @current_tag = :android
      end
    end

    @jobs = JenkinsJob.where("build_number > 0")
    @clients = ClientVersion.select(:id,:job_name, :created_at, :svn_revision,:status, :app_name,:app_url).where(:client_tag => @current_tag).order("id desc").limit(50)
  end

  def show

    @client = ClientVersion.find(params[:id])
    @client2 = ClientVersion.select(:svn_revision).where("id < #{@client.id}").order("id desc").first
    @logs = ClientSvnLog.where(:client_version_id => @client.id)
    if nil != @client2 and false == @client.svn_fetched then
      svn_url = nil
      job =JenkinsJob.where(:id => @client.job_name).first
      if nil != job and not job.svn_url.empty? then
        svnlogxml = `/usr/bin/svn log #{job.svn_url} -r #{@client2.svn_revision + 1}:#{@client.svn_revision} --xml`
        svn_log = XmlSimple.xml_in(svnlogxml,  { "forcearray" => false })
        @logs = []
        @client.update_attributes({:svn_fetched => true})
        if nil != svn_log["logentry"] and 0 < svn_log["logentry"].length then
          if true  == svn_log["logentry"].is_a?(Array) then
            #puts svn_log["logentry"].to_json
            svn_log["logentry"].each do |l|
              @logs << ClientSvnLog.create({
                                               :client_version_id => @client.id,
                                               :revision => l["revision"],
                                               :committed_at => Time.parse(l["date"]),
                                               :message => l["msg"],
                                               :author => l["author"]
                                           })
            end
          else
            l = svn_log["logentry"]
            @logs << ClientSvnLog.create({
                                             :client_version_id => @client.id,
                                             :revision => l["revision"],
                                             :committed_at => Time.parse(l["date"]),
                                             :message => l["msg"],
                                             :author => l["author"]
                                         })
          end

        end
      end
    end
    @feedbacks = ClientFeedback.where(:client_version_id => @client.id).all()
  end

  def feedback
    clientVersionId = params[:id]
    message = params[:message]
    ClientFeedback.create({
                              :client_version_id => clientVersionId,
                              :message => message,
                              :author => ""
                          })
    status_id = params[:status_id].to_i
    if 1 == status_id then
      client = ClientVersion.find(clientVersionId)
      client.update_attributes({
                                   :status => 1
                               })
    elsif "0" == params[:status_id] then
      client = ClientVersion.find(clientVersionId)
      client.update_attributes({
                                   :status => 0
                               })
    end
    feedbacks = ClientFeedback.where(:client_version_id => clientVersionId).all()
    respond_to do |format|
      format.html{

      }
      format.text{
        render :partial => "foreach_feedback_item", :locals =>{:feedbacks => feedbacks}
      }
    end
  end
end
