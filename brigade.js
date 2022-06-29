const { events, Job, Group } = require('brigadier');

const nodeImage = 'node:14';

const sonarCliImage = 'sonarsource/sonar-scanner-cli';

const dockerImage = 'docker:dind';

const kubectlImage = 'bitnami/kubectl';

const dest = '/mnt/brigade/share';


// Triggers the event

events.on('exec', (e, project) => {


// Job for Installing Application Dependency

    const npmJob = new Job('npm-build-test', nodeImage);

    npmJob.env = {

// Place these Nexus credentials while creating brigade project

        NEXUS_AUTH: project.secrets.nexusAuth,
        NEXUS_EMAIL: project.secrets.nexusEmail,
        NEXUS_REGISTRY: project.secrets.nexusRegistry

    };

    npmJob.tasks = [

        'set -x',
        'cd /src',
        'mv .env.sample .env',
        'cd ..',
        'tar -cvzf js-package.tar.gz src/',
        `tar -xvf js-package.tar.gz -C ${dest}`,
        `cd ${dest}/src`,
        
// Configuring Nexus Repo with Npm

        'npm config set loglevel verbose',
        'npm config set registry $NEXUS_REGISTRY',
        'npm config set _auth $NEXUS_AUTH',
        'npm config set email $NEXUS_EMAIL',
        'npm config set always-auth true',
        'npm install',
        'npm run lint:fix',
        'npm run test:c'

    ];


// Job for Sonarqube

    const sonarJob = new Job('sonarqube', sonarCliImage);

    sonarJob.env = {

// Place these Sonarqube while creating brigade project

        SONAR_AUTH: project.secrets.sonarAuth,
        SONAR_PROJ_KEY: project.secrets.sonarKey,
        SONAR_URL: project.secrets.sonarUrl

    }

    sonarJob.tasks = [

         'set -x',
         `cd ${dest}/src`,
         'sonar-scanner \
            -Dsonar.projectKey=$SONAR_PROJ_KEY \
            -Dsonar.host.url=$SONAR_URL \
            -Dsonar.login=$SONAR_AUTH \
            -Dsonar.sources=.'        
    ];


// Job for Docker Build & Push

    const dockerPack = new Job('docker-packaging', dockerImage);

    dockerPack.privileged = true;                                        // dind needs to run in privileged mode

    dockerPack.env = {

        DOCKER_DRIVER: 'overlay',

// Place these Docker credentials while creating brigade project

        DOCKER_USER: project.secrets.dockerUser,
        DOCKER_PASS: project.secrets.dockerPass,
        DOCKER_REGISTRY: project.secrets.dockerRegistry

    };

    dockerPack.tasks = [

        'dockerd-entrypoint.sh &',                               // Start the docker daemon
        'sleep 30',                                              // Grant it enough time to be up and running
        `cd ${dest}/src`,
        'docker build -t $DOCKER_REGISTRY:latest .',             // Replace with your own image tag
        'docker login -u $DOCKER_USER -p $DOCKER_PASS',          // Login to Dockerhub
        'docker push $DOCKER_REGISTRY:latest'                    // Replace with your own image tag

    ];


// Job for Deploying Application On Minikube

    const deployJob = new Job('deploy-application', kubectlImage);

    deployJob.tasks = [

        `cd ${dest}/src/Deployment`,

// Applying yaml file

        'kubectl apply -f mongo_deploy.yaml',
        'kubectl apply -f mongo_svc.yaml',
        'kubectl apply -f starterkit_deploy.yaml',
        'kubectl apply -f starterkit_svc.yaml',
        'kubectl apply -f redis_config.yaml',
        'kubectl apply -f redis_deploy.yaml',
        'kubectl apply -f redis_svc.yaml'

    ];


// Shared Storage for all Jobs

    npmJob.storage.enabled = true;
    sonarJob.storage.enabled = true;
    dockerPack.storage.enabled = true;
    deployJob.storage.enabled = true;


    Group.runEach([npmJob, sonarJob, dockerPack, deployJob]);

});
