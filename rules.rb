#Etsy Foodcritic rules
@coreservices = ["httpd", "mysql", "memcached", "postgresql-server"]

rule "ETSY001", "Package or yum_package resource used with :upgrade action" do
  tags %w{style recipe etsy}
  recipe do |ast|
    pres = find_resources(ast, :type => 'package').find_all do |cmd|
      cmd_str = (resource_attribute(cmd, 'action') || resource_name(cmd)).to_s
      cmd_str.include?('upgrade')
    end
    ypres = find_resources(ast, :type => 'yum_package').find_all do |cmd|
      cmd_str = (resource_attribute(cmd, 'action') || resource_name(cmd)).to_s
      cmd_str.include?('upgrade')
    end
  pres.concat(ypres).map{|cmd| match(cmd)}
  end
end

rule "ETSY002", "Execute resource used to run git commands" do
  tags %w{style recipe etsy}
  recipe do |ast|
    pres = find_resources(ast, :type => 'execute').find_all do |cmd|
      cmd_str = (resource_attribute(cmd, 'command') || resource_name(cmd)).to_s
      cmd_str.include?('git ')
    end.map{|cmd| match(cmd)}
  end
end

rule "ETSY003", "Execute resource used to run curl or wget commands" do
  tags %w{style recipe etsy}
  recipe do |ast|
    pres = find_resources(ast, :type => 'execute').find_all do |cmd|
      cmd_str = (resource_attribute(cmd, 'command') || resource_name(cmd)).to_s
      (cmd_str.include?('curl ') || cmd_str.include?('wget  '))
    end.map{|cmd| match(cmd)}
  end
end

# This rule does not detect execute resources defined inside a conditional, as foodcritic rule FC023 (Prefer conditional attributes)
# already provides this. It's recommended to use both rules in conjunction. (foodcritic -t etsy,FC023)
rule "ETSY004", "Execute resource defined without conditional or action :nothing" do
  tags %w{style recipe etsy}
  recipe do |ast,filename|
    pres = find_resources(ast, :type => 'execute').find_all do |cmd|
      cmd_actions = (resource_attribute(cmd, 'action') || resource_name(cmd)).to_s
      condition = cmd.xpath('//ident[@value="only_if" or @value="not_if" or @value="creates"][parent::fcall or parent::command or ancestor::if]')
      (condition.empty? && !cmd_actions.include?("nothing"))
    end.map{|cmd| match(cmd)}
  end
end

rule "ETSY005", "Action :restart sent to a core service" do
  tags %w{style recipe etsy}
  recipe do |ast, filename|
    ast.xpath('//command[ident/@value = "notifies"]/args_add_block[descendant::symbol/ident/@value="restart"]/descendant::method_add_arg[fcall/ident/@value="resources"]/descendant::assoc_new[symbol/ident/@value="service"]/descendant::tstring_content').select{|notifies| @coreservices.include?(notifies.attribute('value').to_s)}
  end
end