#
# Manifest for standalone CEPH cluster installation
#


node 'ceph-node-1','ceph-node-2','ceph-node-3' {

##CEPH Secrets
#
$ceph_secret_admin              = "AQCAJKhf6F4BNhAA1O6Z6TFJ/gzOYinlug4b1g=="
$ceph_secret_bootstrap          = "AQCPJKhfZM8UIRAAzZodoYHq3+at/cK+oA+YHA=="
$ceph_bootstrap_mdskey          = "AQC1Jahf2Au7FhAA4peSrxcZ0gq9dsresb0ylg=="
$ceph_mon_key                   = "AQC2Jahf02jIKBAAZ//xCDZP9El1TC/DuqmM0g=="
$ceph_mgr_key                   = "AQC3JahfzcqoMxAAataGT44pqgZ0h/8IbSYYWg=="
$ceph_secret_onedata            = "AQC4JahfBSk5NhAANTBR+vnPJ0ZKy1XdZ2YKRw=="

##CEPH OSD configuration
$osd_configure                  = false

##CEPH PARAMS - configure
$ceph_fsid              = "f65809d3-7961-4cd7-b731-a9bc94bc6e9c"
# Uncomment if auth_type is different from 'cephx'
#$ceph_auth_type        = "cephx"
# MON hostname
$ceph_mon_initmemb      = "ceph-node-1,ceph-node-2,ceph-node-3"
# MON FQDN
$ceph_mon_host          = "ceph-node-1.cloud.cnaf.infn.it,ceph-node-2.cloud.cnaf.infn.it,ceph-node-3.cloud.cnaf.infn.it"
$ceph_osdpool_pgnum     = "100"
$ceph_osdpool_pgpnum    = "100"
$ceph_osdpool_size      = "3"
$ceph_osdpool_minsize   = "2"
$ceph_cluster_network   = "192.168.1.0/24"
$ceph_public_network    = "192.168.1.0/24"

##CEPH POOLS WITH RADOSGW ENABLED (CEPH 10.2)- configure
$ceph_pool =  {'onestorage'                    => { pg_num => '16'}}


##CEPH OSD CONFIGURATION with integrated Journal - configure
$ceph_osd  =  {'/dev/vdb' => { store_type => 'bluestore'}}


# Ceph
##OSD

  if $osd_configure {
    create_resources( ceph::osd, $ceph_osd )

##POOL
    create_resources( ceph::pool, $ceph_pool )
  }

##KEY
  ceph::key {
   'client.admin':
     user => 'ceph',
     group => 'ceph',
     secret => $ceph_secret_admin,
     cap_mon => 'allow *',
     cap_osd => 'allow *',
     cap_mds => 'allow *',
     cap_mgr => 'allow *',
     inject => true,
     inject_as_id => 'mon.',
     inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring";

   'client.bootstrap-osd':
     user => 'ceph',
     group => 'ceph',
     secret => $ceph_secret_bootstrap,
     cap_mon => 'allow profile bootstrap-osd',
     keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
     inject => true,
     inject_as_id => 'mon.',
     inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring";

   'client.bootstrap-mgr':
     user => 'ceph',
     group => 'ceph',
     secret => $ceph_secret_bootstrap,
     cap_mon => 'allow profile mgr',
     cap_osd => 'allow *',
     cap_mds => 'allow *',
     keyring_path => '/var/lib/ceph/bootstrap-mgr/ceph.keyring',
     inject => true,
     inject_as_id => 'mon.',
     inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring";

   'client.onedata':
     user => 'ceph',
     group => 'ceph',
     secret => $ceph_secret_onedata,
     cap_mon => 'allow rwx',
     cap_osd => 'allow class-read object_prefix rbd_children, allow rwx pool=onestorage',
     inject => true,
     inject_as_id => 'mon.',
     inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",

  }



# Classes
# CEPH
  class {'ceph::profile::params':
     fsid                       => $ceph_fsid,
# Uncomment if auth_type is different from 'cephx'
#     authentication_type        => $ceph_auth_type,
     mon_initial_members        => $ceph_mon_initmemb,
     mon_host                   => $ceph_mon_host,
     osd_pool_default_pg_num    => $ceph_osdpool_pgnum,
     osd_pool_default_pgp_num   => $ceph_osdpool_pgpnum,
     osd_pool_default_size      => $ceph_osdpool_size,
     osd_pool_default_min_size  => $ceph_osdpool_minsize,
     cluster_network            => $ceph_cluster_network,
     public_network             => $ceph_public_network,
     mon_key                    => $ceph_mon_key,
     mgr_key                    => $ceph_mgr_key,
  } ->
  class { 'ceph::profile::base': } ->
  class { 'ceph::profile::mon': } ->
  class { 'ceph::profile::mgr': }

}
