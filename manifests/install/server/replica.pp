#
class easy_ipa::install::server::replica {
  $replica_install_cmd = "\
/usr/sbin/ipa-replica-install \
  --force-join=${easy_ipa::force_join} \
  --principal=${easy_ipa::final_domain_join_principal} \
  --admin-password='${easy_ipa::final_domain_join_password}' \
  ${easy_ipa::install::server::server_install_cmd_opts_hostname} \
  --realm=${easy_ipa::final_realm} \
  --domain=${easy_ipa::domain} \
  --server=${easy_ipa::ipa_master_fqdn} \
  ${easy_ipa::install::server::server_install_cmd_opts_setup_dns} \
  ${easy_ipa::install::server::server_install_cmd_opts_forwarders} \
  ${easy_ipa::install::server::server_install_cmd_opts_ip_address} \
  ${easy_ipa::install::server::server_install_cmd_opts_no_ntp} \
  ${easy_ipa::install::server::server_install_cmd_opts_no_ui_redirect} \
  ${easy_ipa::install::server::server_install_cmd_opts_force_join} \
  --unattended"

  # TODO: config-show and grep for IPA\ masters
  file { '/etc/ipa/primary':
    ensure  => 'file',
    content => 'Added by IPA Puppet module. Designates primary master. Do not remove.',
  }
  -> exec { "server_install_${easy_ipa::ipa_server_fqdn}":
    command   => $replica_install_cmd,
    timeout   => 0,
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    notify    => Easy_ipa::Helpers::Flushcache["server_${easy_ipa::ipa_server_fqdn}"],
    before    => Service['sssd'],
  }
  -> cron { 'k5start_root':
    command => '/usr/bin/k5start -f /etc/krb5.keytab -U -o root -k /tmp/krb5cc_0 > /dev/null 2>&1',
    user    => 'root',
    minute  => '*/1',
    require => Package[$easy_ipa::kstart_package_name],
  }

}
