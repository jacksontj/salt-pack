# Import base config
{% import "setup/debian/map.jinja" as build_cfg %}

{% set os_codename = 'wheezy' %}
{% set prefs_text = 'Package: *
        Pin: origin ""
        Pin-Priority: 1001
        Package: *
        Pin: release a=' ~ os_codename ~ '-updates
        Pin-Priority: 770
        Package: *
        Pin: release a=' ~ os_codename ~ '-backports
        Pin-Priority: 750
        Package: *
        Pin: release a=' ~ os_codename ~ '
        Pin-Priority: 720
        Package: *
        Pin: release a=oldoldstable
        Pin-Priority: 700
' %}


include:
  - setup.debian
  - setup.debian.gpg_agent


build_additional_pkgs:
  pkg.installed:
    - pkgs:
      - python-support


build_pbldhooks_rm_G05:
  file.absent:
    - name: {{build_cfg.build_homedir}}/.pbuilder-hooks/G05apt-preferences


build_pbldhooks_rm_D04:
  file.absent:
    - name: {{build_cfg.build_homedir}}/.pbuilder-hooks/D04update_local_repo


build_pbldrc_rm:
  file.absent:
    - name: {{build_cfg.build_homedir}}/.pbuilderrc


build_prefs_rm:
  file.absent:
    - name: /etc/apt/preferences


build_pbldhooks_file_G05:
  file.append:
    - name: {{build_cfg.build_homedir}}/.pbuilder-hooks/G05apt-preferences
    - makedirs: True
    - text: |
        #!/bin/sh
        set -e
        cat > "/etc/apt/preferences" << EOF
        {{prefs_text}}
        EOF


build_pbldhooks_file_D04:
  file.append:
    - name: {{build_cfg.build_homedir}}/.pbuilder-hooks/D04update_local_repo
    - makedirs: True
    - text: |
        #!/bin/sh
        # path to local repo
        LOCAL_REPO="{{build_cfg.build_dest_dir}}"
        # Generate a Packages file
        ( cd ${LOCAL_REPO} ; /usr/bin/apt-ftparchive packages . > "${LOCAL_REPO}/Packages" )
        # Update to include any new packagers in the local repo
        apt-get --allow-unauthenticated update


build_pbldhooks_perms:
  file.directory:
    - name: {{build_cfg.build_homedir}}/.pbuilder-hooks/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 755
    - recurse:
        - user
        - group
        - mode


build_pbldrc:
  file.append:
    - name: {{build_cfg.build_homedir}}/.pbuilderrc
    - text: |
        DIST="{{os_codename}}"
        LOCAL_REPO="{{build_cfg.build_dest_dir}}"

        # create local repository if it doesn't exist,
        # such as during initial 'pbuilder create'
        if [ ! -d ${LOCAL_REPO} ] ; then
            mkdir -p ${LOCAL_REPO}
        fi
        if [ ! -e ${LOCAL_REPO}/Packages ] ; then
            touch ${LOCAL_REPO}/Packages
        fi

        BINDMOUNTS="${LOCAL_REPO}"
        EXTRAPACKAGES="apt-utils"
        if [ -n "${DIST}" ]; then
          TMPDIR=/tmp
          BASETGZ="`dirname $BASETGZ`/${DIST}-base.tgz"
          DISTRIBUTION=${DIST}
          APTCACHE="/var/cache/pbuilder/${DIST}/aptcache"
        fi
        HOOKDIR="${HOME}/.pbuilder-hooks"
        OTHERMIRROR="deb [trusted=yes] file:${LOCAL_REPO} ./ | deb http://ftp.us.debian.org/debian/ {{os_codename}}-updates main contrib | deb http://ftp.us.debian.org/debian/ {{os_codename}}-backports main contrib | deb http://ftp.us.debian.org/debian/ {{os_codename}} main contrib "


build_prefs:
  file.append:
    - name: /etc/apt/preferences
    - text: |
        {{prefs_text}}

#36569 work-around reboot Wheezy setting HOME to '/'
home_env:
  environ.setenv:
    - name: HOME
    - value: {{build_cfg.build_homedir}}
    - update_minion: True

