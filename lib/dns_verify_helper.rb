require 'net/dns/resolver'
module DnsVerifyHelper
  def verify_dns!
    # expects self.expected_dns to be {:hostname, :domain, :a => [], :cname => []} (either :a or :cname please)
    # expects self.dns_verify_last_log and self.dns_verify_last_at
    # expects either self.dns_verify_last_successful or self.verified

    self.dns_verify_last_log = ""
    self.dns_verify_last_at = DateTime.now
    valid = false
    
    expected = self.expected_dns

    nsname_rsp = Net::DNS::Resolver.start(expected[:domain], Net::DNS::NS)
      
    self.dns_verify_last_log += nsname_rsp.to_s + "\n--------\n"

    nsnames = nsname_rsp.answer.map{|x| x.nsdname if x.respond_to? 'nsdname'}.select{|x| x}
    nsname = nsnames[0]

    if nsname
      self.dns_verify_last_log += "\nAuthoritative Nameserver found: #{nsname}\n--------\n"
      nsaddr = Net::DNS::Resolver.start(nsname, Net::DNS::A).answer[0].address

      r = Net::DNS::Resolver.new(:nameserver=>nsaddr.to_s)

      rsp = r.search(expected[:hostname], expected.keys.include?(:cname) ? Net::DNS::CNAME : Net::DNS::A)

      self.dns_verify_last_log += rsp.to_s + "\n"

      if rsp.answer.length>0
        if expected.keys.include?(:cname)
          expected[:cname] = [expected[:cname]].flatten
          valid = rsp.answer.length > 0 && expected[:cname].map{|x| rsp.answer[0].cname.starts_with?(x)}.select{|x| x}.length>0
        else
          valid = rsp.answer.length > 0 && expected[:a].include?(rsp.answer[0].address.to_s)
        end
      else
        valid = false
        self.dns_verify_last_log += "--------\nNo answer for #{expected[:hostname]}\n"
      end

      if self.respond_to? 'dns_verify_last_successful'
        if valid
          self.dns_verify_last_successful = Time.now
        else
          self.dns_verify_last_successful = nil
        end
      end
      if self.respond_to? 'verified'
        self.verified = valid
      end
    else
      self.dns_verify_last_log += "\ncouldn't find a qualified NS record for #{expected[:domain]}\n"
    end
  rescue => e
    puts e
    Rails.logger.error "ERROR while verifying hostname: #{e.message}\n  #{e.backtrace.join("\n")}"
    self.dns_verify_last_log += "Internal error, please contact support\n"
    self.dns_verify_last_successful += nil
  ensure
    save(:validate => false)
    return valid
  end
end
