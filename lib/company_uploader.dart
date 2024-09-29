import 'package:firebase_database/firebase_database.dart';

class TechCompaniesUploader {
  final DatabaseReference _companyRef = FirebaseDatabase.instance.ref("companies");

  // Sample list of tech companies (you can replace this with a dynamic list)
  final List<String> _techCompanies = [
    'Snap Inc', 'Dropbox', 'HP', 'Dell Technologies',
    'LG Electronics', 'Samsung Electronics', 'Sony', 'Panasonic', 'ASUS',
    'Lenovo', 'Foxconn', 'Vimeo', 'Red Hat', 'Palantir', 'Epic Games',
    'GitHub', 'Atlassian', 'Stripe', 'DoorDash', 'Robinhood', 'SpaceX',
    'Blue Origin', 'Garmin', 'Grubhub', 'Zillow', 'DocuSign', 'LinkedIn',
    'Pinterest', 'WeWork', 'Etsy', 'Kickstarter', 'OpenAI', 'Lyft', 'TikTok',
    'Dell EMC', 'Wipro', 'Infosys', 'TCS', 'Cognizant', 'Capgemini', 'Accenture',
    'KPMG', 'Deloitte', 'PwC', 'McKinsey & Company', 'Boston Dynamics', 'Veeva Systems',
    'Coupa Software', 'ZoomInfo', 'RingCentral', 'GoDaddy', 'Namecheap', 'DigitalOcean',
    'Vultr', 'OVHcloud', 'Snowflake', 'Cloudera', 'DataRobot', 'Tableau', 'UiPath',
    'Alteryx', 'Splunk', 'ServiceNow', 'Workday', 'Zendesk', 'Tenable', 'Okta',
    'Elastic', 'MongoDB', 'Postman', 'GitLab', 'Docker', 'HashiCorp', 'Kubernetes',
    'Ansible', 'Terraform', 'Jfrog', 'Akamai', 'Cloudflare', 'Fastly', 'Netlify',
    'Heroku', 'Amazon AWS', 'Microsoft Azure', 'Google Cloud', 'IBM Cloud',
    'Oracle Cloud', 'Alibaba Cloud', 'Linode', 'Hetzner', 'Scaleway', 'Rancher',
    'OpenShift', 'Mesosphere', 'VMware', 'Citrix', 'Red Hat OpenStack', 'SUSE',
    'Chef', 'Puppet', 'SaltStack', 'Vault', 'Consul', 'Nomad', 'Vagrant',
    'Artifactory', 'XebiaLabs', 'Sonatype', 'Maven', 'Gradle', 'Jenkins',
    'Bamboo', 'CircleCI', 'Travis CI', 'GitLab CI', 'Bitbucket Pipelines',
    'GoCD', 'Spinnaker', 'Octopus Deploy', 'TeamCity', 'Codeship', 'Wercker',
    'Semaphore', 'Drone', 'Buildkite', 'AppVeyor', 'Hudson', 'CruiseControl',
    'Apache Continuum', 'Phabricator', 'Review Board', 'Gerrit', 'Crucible',
    'GitKraken', 'Sourcetree', 'TortoiseGit', 'Git Extensions', 'Fork',
    'Tower', 'SmartGit', 'Git Cola', 'GitUp', 'Magit', 'GitBash', 'SourceForge',
    'Codeplex', 'Google Code', 'Launchpad', 'Savannah', 'Tigris', 'Fossil',
    'Gogs', 'Gitea', 'SourceHut', 'Read the Docs', 'Sphinx', 'Jekyll',
    'Hugo', 'Hexo', 'MkDocs', 'VuePress', 'Docusaurus', 'Gatsby', 'Gridsome',
    'Eleventy', 'Sapper', 'Angular Universal', 'NestJS', 'Express', 'Fastify',
    'Koa', 'Hapi', 'Meteor', 'Sails.js', 'LoopBack', 'KeystoneJS', 'Feathers',
    'AdonisJS', 'Blitz.js', 'FoalTS', 'RedwoodJS', 'Strapi', 'Ghost',
    'Contentful', 'Netlify CMS', 'Sanity', 'Prismic', 'Directus',
    'Cockpit', 'Storyblok', 'Forestry', 'GraphCMS', 'DatoCMS', 'Contentstack',
    'Agility CMS', 'Kentico Kontent', 'Umbraco', 'Sitecore', 'Adobe Experience Manager',
    'Drupal', 'Joomla', 'Typo3', 'DNN', 'Liferay', 'Magnolia', 'Sitefinity',
    'AMD', 'Adobe', 'Airbnb', 'Alibaba Group', 'Amazon', 'Apple', 'Baidu',
    'ByteDance', 'Cisco Systems', 'Google', 'Huawei', 'IBM', 'Intel',
    'Microsoft', 'Netflix', 'Nvidia', 'Oracle', 'PayPal', 'Qualcomm',
    'SAP', 'Salesforce', 'Shopify', 'Slack', 'Spotify', 'Square',
    'Tencent', 'Tesla', 'Twitter', 'Uber','Xiaomi','Zoom'
  ];




  // Function to upload tech companies to Firebase
  Future<void> uploadCompanies() async {
    try {
      for (String company in _techCompanies) {
        // Store company name as a key in the 'companies' node
        await _companyRef.child(company).set({
          'companyName': company,
        });
      }
      print("Tech companies uploaded successfully.");
    } catch (e) {
      print("Error uploading tech companies: $e");
    }
  }
}
