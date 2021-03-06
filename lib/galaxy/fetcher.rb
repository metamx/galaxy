require 'galaxy/temp'
require 'galaxy/host'
require 'uri'

module Galaxy
    class Fetcher
        def initialize base_url, http_user, http_password, log
            @base, @http_user, @http_password, @log = base_url, http_user, http_password, log
        end

        # return path on filesystem to the binary
        def fetch type, version, extension="tar.gz"
            core_url = "#{@base}/#{type}-#{version}.#{extension}"
            tmp = Galaxy::Temp.mk_auto_file "galaxy-download"
            @log.info("Fetching #{core_url} into #{tmp}")
            if @base =~ /^https?:/
                begin
                    curl_command = "curl -D - -L #{core_url} -o #{tmp} -s"
                    if !@http_user.nil? && !@http_password.nil?
                      curl_command << " -u #{@http_user}:#{@http_password}"
                    end

                    @log.debug("Running CURL command: #{curl_command}")
                    output = Galaxy::HostUtils.system(curl_command)
                rescue Galaxy::HostUtils::CommandFailedError => e
                    raise "Failed to download archive #{core_url}: #{e.message}"
                end
                status = output.first
                (protocol, response_code, response_message) = status.split
                unless response_code == '200'
                    raise "Failed to download archive #{core_url}: #{status}"
                end
            elsif @base =~ /^s3:/
                begin
                    awscli_command = "aws s3 cp #{core_url} #{tmp}"

                    @log.debug("Running awscli command: #{awscli_command}")
                    output = Galaxy::HostUtils.system(awscli_command)
                rescue Galaxy::HostUtils::CommandFailedError => e
                    raise "Failed to download archive #{core_url}: #{e.message}"
                end
            elsif @base =~ /^gs:/
                begin
                    gsutil_command = "gsutil cp #{core_url} #{tmp}"

                    @log.debug("Running gsutil command: #{gsutil_command}")
                    output = Galaxy::HostUtils.system(gsutil_command)
                rescue Galaxy::HostUtils::CommandFailedError => e
                    raise "Failed to download archive #{core_url}: #{e.message}"
                end
            else
                open(core_url) do |io|
                    File.open(tmp, "w") { |f| f.write(io.read) }
                end
            end
            return tmp
        end
    end
end
