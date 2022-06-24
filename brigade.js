const { events, Job, Group } = require('brigadier');

const nodeImage = 'node:14-alpine';

const sonarCliImage = 'sonarsource/sonar-scanner-cli';

const dockerImage = 'docker:dind';

const kubectlImage = 'bitnami/kubectl';

const dest = '/mnt/brigade/share';

// Triggers the event

events.on('push', (e, project) => {

    // Job for Installing Application Dependency

    const buildJob = new Job('dependency-installation', nodeImage);

    buildJob.env = {

        // Place these Nexus credentials while creating brigade project

        NEXUS_AUTH: project.secrets.nexusAuth,
        NEXUS_EMAIL: project.secrets.nexusEmail,
        NEXUS_REGISTRY: project.secrets.nexusRegistry

    };

    buildJob.tasks = [

        'cd /src',

        // Configuring Nexus Repo with Npm

        'npm config set loglevel verbose',
        'npm config set registry $NEXUS_REGISTRY',
        'npm config set _auth $NEXUS_AUTH',
        'npm config set email $NEXUS_EMAIL',
        'npm config set always-auth true',
        'npm install',
        'npm run build',
        'cd ..',
        'tar -cvzf js-package.tar.gz src/',
        `mv js-package.tar.gz ${dest}`,
        `cd ${dest}`,
        'tar -xvf js-package.tar.gz',
        'rm -rf js-package.tar.gz',
        'cd /src',
        `mv .env.sample ${dest}/src/.env`

    ];

    // Job for Application Unit Test

    // var unitTestJob = new Job('unit-test', nodeImage);

    // unitTestJob.timeout= 3600000;

    // unitTestJob.tasks = [

    //   `cd ${dest}/src`,
    //   'ls -lart',
    //   'npm run lint:fix',
    //   'npm run test:c || true'

    // ];

    // Job for Sonarqube

    // var sonarJob = new Job('sonarqube', sonarCliImage);

    // sonarJob.env = {

    // Place these Sonarqube while creating brigade project

    //   SONAR_AUTH: project.secrets.sonarAuth,
    //   SONAR_PROJ_KEY: project.secrets.sonarKey,
    //   SONAR_URL: project.secrets.sonarUrl,
    //   SONAR_BRANCH: project.secrets.sonarBranch

    // }

    // sonarJob.tasks = [

    //  `cd ${dest}/src`,
    //  'sonar-scanner \
    //     -Dsonar.branch.name=$SONAR_BRANCH \
    //     -Dsonar.projectKey=$SONAR_PROJ_KEY \
    //     -Dsonar.sources=. \
    //     -Dsonar.test.inclusions=src/**/*.ts \
    //     -Dsonar.exclusions=src/entities/*.ts,src/index.ts,src/**/*.test.ts,src/**/*.spec.ts \
    //     -Dsonar.host.url=$SONAR_URL \
    //     -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
    //     -Dsonar.typescript.lcov.reportPaths=coverage/lcov.info \
    //     -Dsonar.testExecutionReportPaths=coverage/test-reporter.xml \
    //     -Dsonar.login=$SONAR_AUTH || true'

    // ];

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
        'docker push $DOCKER_REGISTRY:latest'                   // Replace with your own image tag

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

    buildJob.storage.enabled = true;
    // unitTestJob.storage.enabled = true;
    // sonarJob.storage.enabled = true;
    dockerPack.storage.enabled = true;
    deployJob.storage.enabled = true;

    Group.runEach([buildJob, dockerPack, deployJob]);
    // Group.runEach([buildJob, unitTestJob, sonarJob, dockerPack, deployJob]);

});
