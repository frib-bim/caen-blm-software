@Library('diag-pipeline') _

diag_build([
  'diagioc_pico8': [
    deployed_as: 'caen-blm-software',
    top_dir: 'epics-driver',
    auto_restart: false,
    deb_packages: [
      'epics-seq-dev',
      'epics-sscan-dev',
      'pico8-dev',
      'pico8-dkms',
      'python3-cothread',
      'python3-matplotlib',
      'python3-numpy',
      'python3-scipy'
    ],
    instances: [
      'ioc-mtca01-pico8',
      'ioc-mtca02-pico8',
      'ioc-mtca03-pico8',
      'ioc-mtca04-pico8',
      'ioc-mtca06-pico8',
      'ioc-mtca07-pico8',
      'ioc-mtca09-pico8',
      'ioc-mtca10-pico8',
      'ioc-mtca11-pico8',
      'ioc-mtca12-pico8',
      'ioc-mtca14-pico8',
      'ioc-mtca15-pico8',
      'ioc-mtca16-pico8',
      'ioc-mtca17-pico8',
      'ioc-mtca19-pico8',
    ]
  ]
])
