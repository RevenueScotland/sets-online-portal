#!/usr/bin/env groovy

/*
 * Jenkins pipeline file for Revenue Scotland
 * 
 */
 
import org.apache.commons.lang.RandomStringUtils

def RUBY_VERSION="3.3.6"

/*
	* Back office names
	*
	* Notes: No def or final here otherwise the constants get bound to just the main part of the program
	* 	and aren't available to the functions
	*/
MAN_BACKOFFICE = "RSTSTST1"
REL_BACKOFFICE = "RSTSTST2"
BOT_BACKOFFICE = "RSTSSMOK"

properties ([
	buildDiscarder(logRotator(daysToKeepStr: '5', numToKeepStr: '5'))
])
    
timestamps {
	def deployed
	def host
	def port
	def seleniumPort
	try {
		node ('revscot-build') {
			codeGitCheckout()
			withRvm("${RUBY_VERSION}") {
				dir ('code') {
					emailChangeLog()
					prepareBuildEnvironment()
					runUnitTests()
					generateDocumentation()
					lintCode()
                    checkCVEs()
					codeStaticAnalysis()
                    checkGemLicenses()
					precompileAssets()
					stashDeployables()
				}
			}
		}
		node ('revscot-docker-build') {
			milestone(2)
			codeGitCheckout()
			lock (resource: "revscot-container-image-build", inversePrecedence: true) {
				dockerImageBuild()
			}
		}


		lock (resource: "${this.getAppName()}-${env.BRANCH_NAME}-autotest", inversePrecedence: true) {
			node ('revscot-docker-auto-run') {
				milestone(3)
				(deployed, host, port) = deployDockeredEnvironment("autotest")
				if (deployed) {
					stage ('Auto Testing') {
						runAutotestPodman(host, port)
					}
				}
			}
		}

		(manualTestName, manualTestLabel, backOfficeLabel) = manualTestEnvironment()

		if (manualTestName?.trim()) {
			node ('revscot-docker-run') {
				stage ('Manual Testing') {
					milestone(4)
					(deployed, host, port) = deployDockeredEnvironment(manualTestName, manualTestLabel, true, backOfficeLabel)
					if (isDevelopBranch() && deployed) {
						deployDockeredEnvironment("backofficetest", "Back Office Test", false, BOT_BACKOFFICE)
					} 
				}
			}
			if (deployed && !isReleaseBuild()) {
				if (waitForManualTestResults()) {
						stage ('Gather Manual Testing Results') {
							node('revscot-build') {
								waitForResults(manualTestName, manualTestLabel)
							}
						}
				} else {
					node('revscot-build') {
						tagReleaseCandiate('rc')
					}
				}
			}
			else if (deployed && isReleaseBuild()) {
					node('revscot-build') {
						tagReleaseCandiate('release')
					}
			}
		}

		currentBuild.result = "SUCCESS"
    } catch (err) {
        currentBuild.result = "FAILURE"
        throw err
    } finally {
		if (currentBuild.result != "ABORTED" && currentBuild.result != "NOT_BUILT") {
	        node ('revscot-build') {
    	        step([$class: 'Mailer', notifyEveryUnstableBuild: false, recipients: "${REVSCOT_DEVELOPERS}", sendToIndividuals: false])
			}
        }
    }
}

def getAppName() {
	return "revscot"
}

def getFullBuildVersion() {
	if (isReleaseBuild()) {
		return releaseVersion() + "." + "${BUILD_NUMBER}"
	} else {
		return "${BUILD_NUMBER}"
	}
}

def getAppUser() {
	return "rsuser"
}

def getTestDelay() {
	return 60;
}

def sendTimeoutEmail() {
	return false;
}

def sendAbortedEmail() {
	return false;
}

def waitForManualTestResults() {
	return false;
}

/*
 * returns true if changes where on the develop branch
 *
 */
def isDevelopBranch() {
	return env.BRANCH_NAME.equalsIgnoreCase("develop")
}

/*
 * returns true if changes where on a release branch
 *
 */
def isReleaseBuild() {
	return env.BRANCH_NAME.contains("release/")
}

/*
 * returns true if changes where on the develop branch
 *
 */
 def isDevelopBuild() {
	 return env.BRANCH_NAME.containers("develop")
 }

/*
 * extracts the version number of the release from the branch name
 * assumes branch names are of the form: release/<app>/<version>
 * withEnv doesn't like entry strings, so return DUMMY when on a
 * non-release branch
 *
 */
def releaseVersion() {
	if (isReleaseBuild()) {
		return env.BRANCH_NAME.tokenize('/')[2]
	} else {
		return "DUMMY"
	}
}

/*
 * returns environment details (name, label) for a manual test type environment
 * based on whether this is a release build or not
 *
 */
 def manualTestEnvironment() {
	 if (isReleaseBuild()) {
		 return ["release", "Release Smoke Test", REL_BACKOFFICE]
	 } else if (isDevelopBranch()) {
		 return ["manualtest", "Manual Test", MAN_BACKOFFICE]
	 } else {
		 return ["", "", ""]
	 }
 }

/*
 * Email a change log to the developers
 *
 */
def emailChangeLog() {
	def changesFromGit = this.getChangeLogAsFormattedString()
	if (changesFromGit?.trim()) {
		emailext attachLog: false, 
			body: "Just to let you know changes have been pushed up to GIT\n${changesFromGit}\n", 
			subject: "New source pushed to the Revenues Scotland repository.", 
			to: "${REVSCOT_DEVELOPERS}"
	}
}

/*
 * Checkout the code
 *
 */
def codeGitCheckout() {
	sh '[ -d code ] && sudo chown -R jenkins:jenkins code || echo'
	checkout([
		$class: 'GitSCM',
		branches: scm.branches,
		extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'code']] + scm.extensions,
		userRemoteConfigs: scm.userRemoteConfigs
	])
}

/*
 * Prepare the build environment
 *
 */
def prepareBuildEnvironment() {
	stage ('Prepare Build Environment') {
		sh 'gem install bundler rake yard rubocop brakeman bundle-audit licensed'
		sh 'bundle config mirror.https://rubygems.org http://lg-bld-ruby01.development.local:9292'
		sh 'bundle install'
        sh 'yarn install --frozen-lockfile'
		milestone(1)
	}
}

/*
 * Generate the documentation, and copy to server
 *
 */
def runUnitTests() {
	stage ('Run Unit Tests') {
        try {
            sh '''
                yarn build
                rm -f log/test.log
                bundle exec rake UNIT_TEST=1 test
            '''
        } catch (err) {
    	    currentBuild.result = "FAILURE"

			def RELEASE_TEXT = this.isReleaseBuild() ? "Release " : ""
			emailext attachLog: true, 
				body: """${RELEASE_TEXT}Unit testing of the ${this.getAppName()} build ${this.getFullBuildVersion()} has failed.

The full console output can be found here: ${env.BUILD_URL}consoleFull

The log files from the test target can be found attached to this email.

""", 
				compressLog: true, 
				subject: "Unit test of the ${this.getAppName()} application, on the ${env.BRANCH_NAME} branch, has failed",
				to: "${REVSCOT_DEVELOPERS}",
                        attachmentsPattern: "log/test.log"

            throw err
                }
	}
}

/*
 * Generate the documentation, and copy to server
 *
 */
def generateDocumentation() {
	stage ('Generate Documentation') {
		sh 'bundle exec rake yard'
		withEnv(["APP=${this.getAppName()}"]) {
			sh 'scp -r doc/* rsdocs@lg-bld-ruby01.development.local:/var/www/html/${APP}'
		}
	}
}

/*
 * Lint the codebase
 *
 */
def lintCode() {
	stage ('Lint Code') {
		sh 'bundle exec rake rubocop'
	}
}

/*
 * Check any included GEMs and Yarn for being out of date, and for any CVEs
 *
 */

def checkCVEs() {
	stage ('Gem/Yarn CVE Check') {
		try {
                        sh '''
                                set +e
                                touch tmp/yarn-audit.txt tmp/bunde-audit.txt
                                bundle-audit update && bundle-audit check > tmp/bunde-audit.txt && bundle_failed=$?
                                yarn audit --no-progress --level info > tmp/yarn-audit.txt && yarn_failed=$?
                                exit $((yarn_failed+bundle_failed))
                        '''
		} catch (err) {
			emailext attachmentsPattern: "tmp/*-audit.txt", 
				subject: "Gem/Yarn CVE check in ${this.getAppName()}", 
				body: "Some GEMs and/or Yarn packages have CVEs in ${this.getAppName()}. Please see attached for more information.", 
				to: "${REVSCOT_DEVELOPERS}"
		}
	}

}

def checkGemLicenses() {
    stage ('Check Gem Licenses') {
        // ignore errors from the license checks for now
        sh '''
            set +e
            licensed cache
            licensed status > tmp/licensed.txt
            echo
        '''
        stash name: "${this.getAppName()}-${this.getFullBuildVersion()}-gem-licenses", includes: 'tmp/licensed.txt'
    }
}

/*
 * Perform security based static analysis on the code base
 *
 */
def codeStaticAnalysis() {
	stage ('Static Analysis') {
		try {
			sh 'brakeman -A -x CheckForceSSL -w2 -q -o tmp/analysis.txt'
		} catch (err) {
			emailext attachmentsPattern: "tmp/analysis.txt", 
				subject: "Static Analysis Failures in ${this.getAppName()}", 
				body: "brakeman found some security issues after scanninng the code base for ${this.getAppName()}. Please see attached for more information, along with the brakeman website: https://brakemanscanner.org/", 
				to: "${REVSCOT_DEVELOPERS}"
			currentBuild.result = "FAILURE"
       throw err
		}
	}
}

/*
 * Precompile the assets into /public - these will be deployed
 * into the reverse proxy, rather then getting rails to serve
 * them up
 *
 */
def precompileAssets() {
	stage ('Precompile Assets') {
		def master_key = ""
		dir ('environment/images/ui') {
				sh 'echo MASTER_KEY=$(grep -oP "RAILS_MASTER_KEY[[:space:]]*\\K[^\\\\\\]*" Dockerfile) > master_key.props'
				def props = readProperties file: "master_key.props"
				master_key=props['MASTER_KEY']
		}
		sh "RAILS_MASTER_KEY=${master_key} RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile"
	}
}

/*
 * Stash deployable assets for later
 *
 */
def stashDeployables() {
	stage ('Stash Deployables') {
		stash name: "${this.getAppName()}-${this.getFullBuildVersion()}", 
			excludes: "environment/**,doc/**,tmp/**,.git/**,.vscode/**,.yardoc/**,.licensed/**,.rubocop.yml,.gitattributes,.gitignore,.licensed.yml,Jenkinsfile,converage/**,tools/**"
	}
}

/*
 * Unstash deployable assets previsouly stashed
 * folder	the name of the folder to unstash the files into
 *
 */
def unstashDeployables(folder) {
	dir (folder) {
		sh "sudo rm -rf *"
		unstash name: "${this.getAppName()}-${this.getFullBuildVersion()}"
	}
}

/*
 * Builds an application's base images
 *
 */
def dockerImageBuild() {
	stage ('Docker Image Build') {
		unstashDeployables("code/environment/images/ui/scratch")
		unstashDeployables("code/environment/images/proxy/scratch")
		dir ('code/environment/images') {
			withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APP_NAME=${this.getAppName()}", "RELEASE_VERSION=${this.releaseVersion()}"]) {
				sh '''
					if [ "${RELEASE_VERSION}" == "DUMMY" ] ; then export RELEASE_VERSION="" ; fi 
					# export DOCKER_HOST=tcp://$(hostname -f):2376
					export DOCKER_REG=lg-bld-cont01.development.local:8443/revscot
					export DOCKER_RELEASE_REG=lg-bld-cont01.development.local:8443/release-revscot
					export SRC_DOCKER_REG=lg-bld-cont01.development.local:8443/base-images
					export SRC_DOCKER_RELEASE_REG=lg-bld-cont01.development.local:8443/release-nds-app-servers
					cd redis
					../build-appserver-base-image.sh ${FULL_BUILD_VERSION} ${APP_NAME}-redis redis "${RELEASE_VERSION}" AAA${APP_NAME}
					cd ../ui
					../build-appserver-base-image.sh ${FULL_BUILD_VERSION} ${APP_NAME}-app app "${RELEASE_VERSION}" AAA${APP_NAME}
					cd ../proxy
					../build-appserver-base-image.sh ${FULL_BUILD_VERSION} ${APP_NAME}-proxy proxy "${RELEASE_VERSION}" AAA${APP_NAME}
					cd ../selenium-firefox
					SRC_DOCKER_REG=lg-bld-cont01.development.local:8443/docker-hub-proxy-cache/selenium SRC_DOCKER_RELEASE_REG=lg-bld-cont01.development.local:8443/docker-hub-proxy-cache/selenium ../build-appserver-base-image.sh ${FULL_BUILD_VERSION} ${APP_NAME}-firefox firefox "${RELEASE_VERSION}" AAA${APP_NAME}
				'''
			}
		}
		if (this.isReleaseBuild()) {
			registerReleaseBuild()
		}
	}
}

/*
 * Register the release build in the list of releaes builds
 *
 */
def registerReleaseBuild() {
		steps.withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPNAME=${this.getAppName()}"]) {
			steps.sh '''
				now=$(date -Ins -u | sed -e 's/,/./'  -e 's/+.*.//')
				curl -X PUT https://lg-core-rel01.development.local:443/api/release -d "{\\"mode\\":\\"add\\",\\"appId\\":\\"${APPNAME}\\",\\"version\\":\\"${FULL_BUILD_VERSION}\\",\\"builtDate\\":\\"${now}\\",\\"exportDate\\":\\"\\"}"
			'''
		}

}
 
/*
 * Deploy a dockered environment
 * environment 			name/type of environment to build the images for
 * environmentLabel 	user readable version of the above
 * askForDeployment	set to true to pause job whilst waiting for user to confirm deployment
 * backOfficeLabel		name of back off this environment uses 
 * 
 */
def deployDockeredEnvironment(String environment, String environmentLabel="", askForDeployment=true, String backOfficeLabel="") {
	def deployed = false
	def host = 0
	def port = 1
	def seleniumPort = 2
	def releaseNotesFile = 3
	def environmentDetails
	def deploy = true
	try {
		codeGitCheckout()
		if (environment == "autotest") {
			environmentDetails=deployAutotestEnvironmentPodman()
			deployed = true
		} else {
			if (askForDeployment) {
				deploy = waitForDeployment(environment, environmentLabel)
			}
			if (deploy) {
				environmentDetails=deployManualTestEnvironment(environment, environmentLabel, backOfficeLabel)
				emailManualTestDeploymentDetails(environmentLabel, environmentDetails[host], environmentDetails[port], environmentDetails[releaseNotesFile])
				deployed = true
			} else {
				environmentDetails = [null, null, null]
			}
		}
		currentBuild.result = "SUCCESS"
	} catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
	return [deployed, environmentDetails[host], environmentDetails[port]]
}

/*
 * Deploy an autotest type environment with Podman
 *
 */
def deployAutotestEnvironmentPodman(String environment = "autotest") {
	try {
		dir('code/environment/deployments') {
			withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "TEST_DELAY=${this.getTestDelay()}", "APP=${this.getAppName()}", 
			         "ENVIRONMENT=${environment}", "USER=${this.getAppUser()}", "RELEASE_VERSION=${this.releaseVersion()}"]) {
				sh '''
					if [ "${RELEASE_VERSION}" == "DUMMY" ] ; then export RELEASE_VERSION="" ; fi 
					export DOCKER_REG=lg-bld-cont01.development.local:8443/revscot
					export DOCKER_RELEASE_REG=lg-bld-cont01.development.local:8443/release-revscot
					sudo -E ./run-app-env.sh $FULL_BUILD_VERSION  ${ENVIRONMENT} ${APP} "${RELEASE_VERSION}" ${USER}
					sleep ${TEST_DELAY}
				'''
			}
			def props = readProperties file: "scratch/${this.getFullBuildVersion()}/${environment}/env.properties"
			currentBuild.result = "SUCCESS"
			return [props["APP_HOST"], props["PROXY_HTTPS_PORT"]]
		}
	} catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
}

/*
 * Deploy a dockered manual test type environment
 * environment		  name/type of environment to build the images for
 * environmentLabel user readable version of the above
 * backOffice				the name of the back office
 *
 */
def deployManualTestEnvironment(String environment, String environmentLabel, String backOffice) {
	try {
		releaseNotesFile = generateReleaseNotes(environment)
		dir('code/environment/deployments') {
			withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "TEST_DELAY=${this.getTestDelay()}", "APP=${this.getAppName()}", "BACKOFFICE=${backOffice}",
			         "ENVIRONMENT=${environment}", "USER=${this.getAppUser()}", "LABEL=${environmentLabel}", "RELEASE_VERSION=${this.releaseVersion()}"]) {
				sh '''
					#!/bin/bash
					if [ "${RELEASE_VERSION}" == "DUMMY" ] ; then export RELEASE_VERSION="" ; fi 
					
			                sudo docker network prune -f
					export DOCKER_REG=lg-bld-cont01.development.local:8443/revscot
					export DOCKER_RELEASE_REG=lg-bld-cont01.development.local:8443/release-revscot
					[ ! -z "$(sudo docker ps -qa --filter name=${APP}.*-${ENVIRONMENT}$)" ] && sudo docker stop $(sudo docker ps -qa --filter "name=${APP}.*-${ENVIRONMENT}$") && sudo docker rm -f $(sudo docker ps -qa --filter "name=${APP}.*-${ENVIRONMENT}$")
					sudo -E ./run-mt-app-env.sh ${FULL_BUILD_VERSION} ${ENVIRONMENT} ${APP} "${RELEASE_VERSION}" ${USER}
					sleep ${TEST_DELAY}
					export IMAGE_VERSION=${FULL_BUILD_VERSION}
					containers=$(grep -Po "container_name:\\s*\\K.+" scratch/${FULL_BUILD_VERSION}/${ENVIRONMENT}/docker-compose.yml | paste -sd " ")
					sudo chown jenkins:jenkins -R scratch/${FULL_BUILD_VERSION}
					echo IMAGES_USED=\\"$(sudo docker inspect --format='{{.Config.Image}}' ${containers} | paste -sd ' ')\\" >> scratch/${FULL_BUILD_VERSION}/${ENVIRONMENT}/env.properties
    					sed 's/>/\\\\\\>/g;s/</\\\\\\</g' scratch/${FULL_BUILD_VERSION}/${ENVIRONMENT}/env.properties > scratch/${FULL_BUILD_VERSION}/${ENVIRONMENT}/escaped-env.properties
    					source scratch/${FULL_BUILD_VERSION}/${ENVIRONMENT}/escaped-env.properties
					./register-new-environment.sh ${APP,,} "${LABEL}" ${FULL_BUILD_VERSION} ${APP_HOST} https://${APP_HOST}:${PROXY_HTTPS_PORT}/${APP}/ ${ENVIRONMENT} "Connected to ${BACKOFFICE} back office"
				'''
			}
			def props = readProperties file: "scratch/${this.getFullBuildVersion()}/${environment}/env.properties"
//			def imagesUsed = props["IMAGES_USED"]
//			if (environment == "manualtest") {
//				node ("${this.getAppName()}-docker-build") {
//					analyseApplicationImages(imagesUsed)
//				}
//			}
			return [props["APP_HOST"], props["PROXY_HTTPS_PORT"], "", releaseNotesFile]
		}
	} catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
}	 

/*
 * Generate some simple release notes
 * environment		name/type of environment to build the images for
 */
def generateReleaseNotes(environment) {
	codeGitCheckout()
	dir('code') {
		outputFile=this.randomFile()
		withEnv(["APP=${this.getAppName()}", "ENVIRONMENT=${environment}", "RELEASE_VERSION=${this.releaseVersion()}",
			       "OUTPUT=${outputFile}"]) {
			sh '''
				#!/bin/bash
				set +e
				# export DOCKER_HOST=tcp://$(hostname -f):2376
				cd tools
				./simpleReleaseNotes.sh app-${ENVIRONMENT} ${APP} latest RSTP > ${OUTPUT}
				echo
			'''
		}
	}
	return outputFile
}

/*
 * generates a random filename
 *
 */
@NonCPS
def randomFile() {
	String randomString = RandomStringUtils.random(18, true, true)
	return '/var/tmp/' + randomString + '.txt'
}

/*
 * Run an autotest test with Podman
 * host			the name of the host where the application is running on
 * port			the port the application is listening on
 * seleniumPort	the port that the selenium server is listening on
 */
def runAutotestPodman(String host, String port, String environment = "autotest") {
	try
	{
		dir ('code') {
			def altVersion = this.getFullBuildVersion().replaceAll('\\.', '-')
			def appHostUrl = "http://${this.getAppName()}-app-${environment}:2099"
			withEnv(["CAPYBARA_DRIVER=selenium_remote_firefox", "APP=${this.getAppName()}", 
			         "FULL_BUILD_VERSION=${altVersion}", "ENVIRONMENT=${environment}", "CAPYBARA_APP_HOST=${appHostUrl}",
					 "COVERAGE_DIR=log/coverage", "COVERAGE_MERGE=true", "CAPYBARA_SAVE_PATH=log/tmp/screenshots"]) {
				sh '''
					#!/bin/bash
					set -x
                    			sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} microdnf install -y dnf oracle-epel-release-el9
                    			sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} dnf config-manager --enable ol9_codeready_builder
                    			sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} dnf module enable nodejs:20
                    			sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} dnf -y install gmp-devel git yarnpkg libyaml-devel
                    			sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} dnf -y group install "Development Tools"

					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} bundle config mirror.https://rubygems.org http://lg-bld-ruby02.development.local:9292
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} bundle config set --local deployment 'true'
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} bundle config set --local with 'development test'
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} bundle install --verbose
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} mkdir -p /var/tmp/share/upload /var/tmp/share/download
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} chmod 777 -R /var/tmp/share/
					sudo -E podman exec -u root ${APP}-app-${ENVIRONMENT} chmod a+w -R .

					sel_hub_ip=$(sudo -E podman exec ${APP}-selenium-hub-${ENVIRONMENT} hostname -i)
					app_no_proxy=$(sudo -E podman exec ${APP}-app-${ENVIRONMENT} env | grep no_proxy),${sel_hub_ip}
					app_NO_PROXY=$(sudo -E podman exec ${APP}-app-${ENVIRONMENT} env | grep NO_PROXY),${sel_hub_ip}

					sudo -E docker exec ${APP}-app-${ENVIRONMENT} sh -c "${app_no_proxy} ${app_NO_PROXY} bundle exec rake COVERAGE_DIR=${COVERAGE_DIR} CAPYBARA_DRIVER=${CAPYBARA_DRIVER}\
						CAPYBARA_REMOTE_URL=http://${sel_hub_ip}:4444/wd/hub CAPYBARA_APP_HOST=${CAPYBARA_APP_HOST} COVERAGE_MERGE=${COVERAGE_MERGE} CAPYBARA_SAVE_PATH=${CAPYBARA_SAVE_PATH}\
						TEST_FILE_UPLOAD_PATH=/var/tmp/share/upload TEST_FILE_DOWNLOAD_PATH=/var/tmp/share/download \
						RAILS_ENV=test NODE_ENV=test cucumber"

					sudo -E docker exec ${APP}-app-${ENVIRONMENT} chmod -R u+w ${COVERAGE_DIR}
					sudo -E docker exec ${APP}-app-${ENVIRONMENT} mv log/test.log log/${ENVIRONMENT}.log
					sudo -E docker exec ${APP}-app-${ENVIRONMENT} bundle exec rake COVERAGE_DIR=${COVERAGE_DIR} CAPYBARA_DRIVER=${CAPYBARA_DRIVER}\
				    	UNIT_TEST=1 CAPYBARA_REMOTE_URL=http://${sel_hub_ip}:4444/wd/hub CAPYBARA_APP_HOST=${CAPYBARA_APP_HOST} COVERAGE_MERGE=${COVERAGE_MERGE} RAILS_ENV=test test
					'''
			}
		}
		postAutotestSuccess(environment)
		currentBuild.result = "SUCCESS"
	} catch (err) {
		postAutotestFailure(host, environment)
		currentBuild.result = "FAILURE"
        throw err
	} finally {
		emailModSecFailures(environment)
		emailLogErrors(environment, host)
        emailDepreciatedMessages(environment, host)
	}
}

/*
 * run post autotest actions on a successful autotest run
 *
 */
def postAutotestSuccess(String environment = "autotest") {

	stopEnvironment(environment)
	deleteEnvironment(environment)
	dir ('code') {
        unstash name: "${this.getAppName()}-${this.getFullBuildVersion()}-gem-licenses"
		withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
			sh '''
				ssh rsdocs@lg-bld-ruby01.development.local "mkdir -p /var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}"
				pushd /var/log/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}/app/
				scp -r coverage rsdocs@lg-bld-ruby01.development.local:/var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}/
				ssh rsdocs@lg-bld-ruby01.development.local "unlink /var/www/html/${APPLICATION}/coverage ; ln -sf /var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}/coverage /var/www/html/${APPLICATION}/coverage"
				popd

                scp tmp/licensed.txt rsdocs@lg-bld-ruby01.development.local:/var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}/
				ssh rsdocs@lg-bld-ruby01.development.local "[ -L "/var/www/html/${APPLICATION}/licensed.txt" ] && unlink /var/www/html/${APPLICATION}/licensed.txt ; ln -sf /var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}/licensed.txt /var/www/html/${APPLICATION}/licensed.txt"
			'''
		}
	}
}

/*
 * run post autotest actions on a failed autotest run
 *
 */
def postAutotestFailure(String host, String environment = "autotest") {

	deleteOldEnvironments(environment)
	stopEnvironment(environment)
	sh 'sudo chown -R jenkins:jenkins code'
	dir ('code') {
		withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
			sh '''
				ssh rsdocs@lg-bld-ruby01.development.local "mkdir -p /var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}"
				pushd /var/log/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}/app/
				sudo mkdir -p tmp ; sudo chmod a+w -R tmp
				echo \'<html><head><title>\'Test Results for ${ENVIRONMENT} of ${APPLICATION} version ${FULL_BUILD_VERSION}\'</title></head>\' > tmp/index.html
				echo \'<body><h2>\'Test Results for ${ENVIRONMENT} of ${APPLICATION} version ${FULL_BUILD_VERSION}\'</h2><p>The following tests failed:</p>\' >> tmp/index.html
				ls tmp/screenshots/ | sed \'s/\\(.*\\)/\\<p\\>\\<a href="\\1"\\>\\1\\<\\/a\\><\\/p\\>/\' >> tmp/index.html
				echo \'<p>Test completed at \'$(date)\'</p></body></html>\' >> tmp/index.html
				mv tmp/index.html tmp/screenshots/index.html
				scp tmp/screenshots/*.{html,png} rsdocs@lg-bld-ruby01.development.local:/var/www/html/${APPLICATION}/${ENVIRONMENT}/${FULL_BUILD_VERSION}/
				rm -rf tmp/screenshots/*
                cd ../video
                sudo zip record.flv.zip record.flv
                sudo rm -rf record.flv
				popd
			'''
			def RELEASE_TEXT = this.isReleaseBuild() ? "Release " : ""
			emailext attachLog: true, 
				body: """${RELEASE_TEXT}Auto testing of the ${this.getAppName()} build ${this.getFullBuildVersion()} has failed.

A report can be found here: http://lg-bld-ruby01.development.local/${this.getAppName()}/${environment}/${this.getFullBuildVersion()}/index.html
(This report will be available for a week)

The full console output can be found here: ${env.BUILD_URL}consoleFull

The log files from the test target can be found on ${host} in /var/log/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/

""", 
				compressLog: true, 
				subject: "Auto test of the ${this.getAppName()} application, on the ${env.BRANCH_NAME} branch, has failed",
				to: "${REVSCOT_DEVELOPERS}"
			echo "${environment} report can be found at: http://lg-bld-ruby01.development.local/${this.getAppName()}/${environment}/${this.getFullBuildVersion()}/index.html"
		}
	}
}

/*
 * Email any mod_security errors
 * environment	name/type of environment to build the images for
 *
 */
def emailModSecFailures(String environment) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
		sh '''
			export wd=/var/tmp/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}
			mkdir -p ${wd}
			chmod o+w ${wd}
			pushd /var/log/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}
			set +e
			echo "# modsec issues" > ${wd}/modsec_issues.env
			if [ -d 'proxy' ] ; then 
				if sudo bash -c '[[ -s "proxy/httpd/modsec_audit.log" ]]' ; then
				echo "#### PROXY MOD_SECURE ERRORS ####" >> ${wd}/modsec_issues.txt
				sudo grep -oE '\\" at .*\\[id \\".*\\"\\]' proxy/httpd/modsec_audit.log > ${wd}/modsec_issues.txt
				if [ $? = "1" ] ; then 
					echo PROXY_ERRORS=0 >> ${wd}/modsec_issues.env
				else
					echo PROXY_ERRORS=1 >> ${wd}/modsec_issues.env
				fi
				else
				echo PROXY_ERRORS=0 >> ${wd}/modsec_issues.env
				fi
			else
				echo PROXY_ERRORS=0 >> ${wd}/modsec_issues.env
			fi
			popd
		'''
		def props = readProperties file: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/modsec_issues.env"
		if (props["PROXY_ERRORS"] == "1") {
			emailext attachmentsPattern: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/modsec_issues.txt", 
				body: "mod_security failures in ${this.appLabel}", 
				subject: "mod_security failures in ${this.appLabel}", 
				to: "${REVSCOT_DEVOPS}"
		}
	}
}
 
	/*
	* Email any logged errors
	* environment	name/type of environment to build the images for
	* host			name of the host the environment was running on
	*
	*/
def emailLogErrors(String environment, String host) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
		sh '''
			export wd=/var/tmp/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}
			mkdir -p ${wd}
			chmod o+w ${wd}
			current=${PWD}
			pushd /var/log/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}
			if [[ ! -f ${current}/app/${ENVIRONMENT}.log ]] ; then
				if [[ -f ${current}/app/test.log ]]; then
					sudo mv ${current}/app/test.log ${current}/app/${ENVIRONMENT}.log
				fi
			fi
			echo > ${wd}/issues.txt
			chmod o+w ${wd}/issues.txt

			if [ -d '${current}/app' ] ; then 
				sudo chmod go+r ${current}/app/${ENVIRONMENT}.log*
				if grep -q -e "FATAL" -e " ERROR " ${current}/app/${ENVIRONMENT}.log*; then 
					echo "#### APP ERRORS ####" >> ${wd}/issues.txt
					grep -B 1 -A 6 -e "FATAL" -e " ERROR " ${current}/app/${ENVIRONMENT}.log* >> ${wd}/issues.txt
					echo UI_ERRORS=1 >> ${wd}/issues.env
				else
					echo UI_ERRORS=0 >> ${wd}/issues.env
				fi
			else
				echo UI_ERRORS=0 >> ${wd}/issues.env
			fi
			popd
		'''
		def props = readProperties file: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/issues.env"

		if (props["UI_ERRORS"] == "1") {
			def RELEASE_TEXT = this.isReleaseBuild() ? "Release " : ""
			emailext attachmentsPattern: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/issues.txt", 
				body: "Application failures in ${this.getAppName()} during ${RELEASE_TEXT}${environment}. A summary is attached.\n\nThe full log files can be found on ${host}, under:\n\nApplication:	   /var/log/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/app/\n", 
				subject: "Application failures in ${this.getAppName()} during ${RELEASE_TEXT}${environment}", 
				to: "${REVSCOT_DEVELOPERS}"
		}
	}
}

def emailDepreciatedMessages(String environment, String host) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
		sh '''
			export wd=/var/tmp/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}
			mkdir -p ${wd}
			chmod o+w ${wd}
			pushd /var/log/${APPLICATION}/${FULL_BUILD_VERSION}/${ENVIRONMENT}

			echo > ${wd}/issues.txt
			chmod o+w ${wd}/issues.txt

			if [ -d 'app' ] ; then 
				sudo chmod go+r app/${ENVIRONMENT}.log*
				if grep -q -e "DEPRECATION" app/${ENVIRONMENT}.log*; then 
					echo "#### DEPRECATION WARNINGS ####" >> ${wd}/issues.txt
					grep -B 1 -A 6 -e "DEPRECATION" app/${ENVIRONMENT}.log* >> ${wd}/issues.txt
					echo DEPRECATION=1 >> ${wd}/issues.env
				else
					echo DEPRECATION=0 >> ${wd}/issues.env
				fi
			else
				echo DEPRECATION=0 >> ${wd}/issues.env
			fi
			popd
		'''
		def props = readProperties file: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/issues.env"

		if (props["DEPRECATION"] == "1") {
			def RELEASE_TEXT = this.isReleaseBuild() ? "Release " : ""
			emailext attachmentsPattern: "/var/tmp/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/issues.txt", 
				body: "Deprecation messages in ${this.getAppName()} during ${RELEASE_TEXT}${environment}. A summary is attached.\n\nThe full log files can be found on ${host}, under:\n\nApplication:	   /var/log/${this.getAppName()}/${this.getFullBuildVersion()}/${environment}/app/\n", 
				subject: "Deprecation messages in ${this.getAppName()} during ${RELEASE_TEXT}${environment}", 
				to: "${REVSCOT_DEVELOPERS}"
		}
	}
}

/*
 * Send interested parties an email about the last manual test type deployment
 * environmentLabel user readable version of the above
 * host				      the name of the host the environment is running on
 * port				      the port number the environment is listening on
 * releaseNotesFile the file containing the release notes
 *
 */
def emailManualTestDeploymentDetails (String environmentLabel, String host, String port, String releaseNotesFile) {
	def releaseNotesContent = readFile releaseNotesFile

	if (environmentLabel == 'Back Office Test' || environmentLabel == 'Back Office Smoke Test') {
		releaseNotesContent = ""
	} else {
		releaseNotesContent = "This contains the following commits: \n\n"+releaseNotesContent
	}

	steps.emailext attachLog: false, 
		body: """A ${environmentLabel} environment for the ${this.getAppName()} has been created. This environment will be available until it is manually replaced by a new one.
							
Links to the environment:
Application: https://${host}:${port}/${this.getAppName()}/

${releaseNotesContent}

Report the success or failure of the manual testing here:
${env.BUILD_URL}input/
""", 
	subject: "${this.getAppName()} ${environmentLabel} environment has been started", 
	to: "${REVSCOT_TESTERS}"
}


/*
 * Wait for the user to start a deployment, or timeout
 * environment		name/type of environment to build the images for
 * environmentLabel user readable version of the above
 *
 */
def waitForDeployment(String environment, String environmentLabel) {
	def startTimeout = false
	def startAborted = false
	try {
		timeout (time: 16, unit: 'HOURS') {
			lock (resource: "${this.getAppName()}-${env.BRANCH_NAME}-${environment}-test-input", inversePrecedence: true) {
				emailext attachLog: false, 
					body: "The ${this.getAppName()} ${environmentLabel} environment can be started, click here: ${env.BUILD_URL}input/", 
					subject: "${this.getAppName()} ${environmentLabel} environment can be started", 
					to: "${REVSCOT_TESTERS}"
				node {
					input "Deploy ${this.getAppName()} ${environmentLabel}, version ${this.getFullBuildVersion()} ?"
					milestone (5)
				}
			}
		}
	} catch (org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution.ExceededTimeout | java.util.concurrent.TimeoutException err) {
		startTimeout = true
	} catch (Exception err) {
		def cause = err.metaClass.respondsTo(err, "getCauses") ? err.getCauses()[0] : null
		if (cause != null && cause.getClass() == org.jenkinsci.plugins.pipeline.milestone.CancelledCause) {
			startAborted = true
		} else {
			def user = cause != null ? cause.getUser() : ""
			if (user.toString() == 'SYSTEM') {
				startTimeout = true
			} else {
				startAborted = true
			}
		}
	}

	if (startTimeout) {
		if (sendTimeoutEmail()) {
			emailext attachLog: false,
				body: "Waiting for response to starting the ${this.getAppName()} ${environmentLabel}, version ${this.getFullBuildVersion()}, environment timed out. This version will not be deployed.", 
				subject: "Waiting for response to starting the ${this.getAppName()} ${environmentLabel} environment ${this.getFullBuildVersion()} timed out",
				to: "${REVSCOT_TESTERS}"
		}
		return false
	} else if (startAborted) {
		if (sendAbortedEmail()) {
			emailext attachLog: false, 
				body: "Starting the ${this.getAppName()} ${environmentLabel}, version ${this.getFullBuildVersion()}, environment was aborted. This version will not be deployed.", 
				subject: "Starting the ${this.getAppName()} ${environmentLabel} environment ${this.getFullBuildVersion()} was aborted", 
				to: "${REVSCOT_TESTERS}"
		}
		return false
	} else {
		return true
	}
}

/* Use Clair to analyse an applications images
 * imagesUsed	space separated list of images to analyse
 */
def analyseApplicationImages(String imagesUsed) {
    try {
        withEnv(["IMAGE_LIST=${imagesUsed}"]) {
            sh '''
                rm -f report-*.html
                for repo_image in ${IMAGE_LIST//\\"/}; do
                    echo Analysing ${repo_image}
                    repo=${repo_image%%/*}
                    image=${repo_image##*/}	   
                    reportName=analysis-${repo}-${image//:/-}
                    ssh ${CLAIR_SERVER} "/opt/clair/analyse-image.sh ${repo}/${image} jenkins password"
                    scp "${CLAIR_SERVER}:/opt/clair/reports/${reportName}.html" report-${image//:/-}.html
                    ssh ${CLAIR_SERVER} "rm -rf /opt/clair/reports/${reportName}.html"
                done
                if test -n "$(find . -maxdepth 1 -name '*.html' -print -quit)" ; then
                    echo Summary of Results > summary.txt
                    remove_junk='-e s~strong~~g -e s~div~~g -e s~/~~g -e s~[<>]~~g '
                    for report in *.html ; do
                        grep -o "Image: [^<]*" ${report} >> summary.txt
                        echo "	" $(grep -o "Total : [[:digit:]]* vulnerabilities" ${report}) >> summary.txt
                        echo "	" $(grep -o "Critical : .*" ${report} | sed ${remove_junk}) >> summary.txt
                        echo "	" $(grep -o "High : .*" ${report} | sed ${remove_junk}) >> summary.txt
                        echo "	" $(grep -o "Medium : .*" ${report} | sed ${remove_junk}) >> summary.txt
                        echo >> summary.txt
                    done
                else
                    echo No Report files found > summary.txt
                fi
            '''
            emailext attachLog: false, 
                body: 'Find attached Clair reports for all images\nSummary of results are:\n\n\${FILE,path="summary.txt"}\n', 
                subject: "Analysis of ${this.getAppName()} manual test images", 
                to: "${REVSCOT_DEVOPS}", 
                attachmentsPattern: 'report-*.html'
        }
    } catch (err) {
        emailext subject: "Build failed to check docker images in ${this.getAppName()}",
            body: "Using Clair to check for CVEs in docker images failed with errors. Check the Jenkins log for more details, which can be found here: ${env.BUILD_URL}consoleFull",
            to: "${REVSCOT_DEVOPS}"
    }
}

/*
 * Wait for the results of any manual test, release smoke testing
 * environment name/type of environment to build the images for
 * environmentLabel user readable version of the above
 * 
 */
def waitForResults(String environment, String environmentLabel) {
	def resultsTimeout = false
	def resultsFailure = false

	milestone (7)
	try {
		timeout (time: 7, unit: 'DAYS') {
			node {
				input "Was manual testing successful, and should this build be tagged as a possible release?"
			}
			milestone (8)
		}
	} catch (org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution.ExceededTimeout | java.util.concurrent.TimeoutException err) {
		resultsTimeout = true
	} catch (Exception err) {
		def cause = err.metaClass.respondsTo(err, "getCauses") ? err.getCauses()[0] : null
		if (cause != null && cause.getClass() == org.jenkinsci.plugins.pipeline.milestone.CancelledCause) {
			resultsFailure = true
		} else {
			def user = cause != null ? cause.getUser() : ""
			if (user.toString() == 'SYSTEM') {
				resultsTimeout = true
			} else {
				resultsFailure = true
			}
		}
	}

	if ( resultsFailure == false && resultsTimeout == false ) {
		tagReleaseCandiate('rc')
	} else {
		if (resultsTimeout) {
			if (sendTimeoutEmail()) {
				emailext attachLog: false, 
					body: "Waiting for the results of the ${this.getAppName()} ${environmentLabel}, version ${this.getFullBuildVersion()}, timed out. This version can not be made into a release.", 
					subject: "Waiting for the results of the ${this.getAppName()} ${environmentLabel} ${this.getFullBuildVersion()} timed out", 
					to: "${REVSCOT_TESTERS}"
			}
			currentBuild.result = "SUCCESS"
		} else if (resultsFailure) {
			echo "User reported ${environmentLabel} failure, marking build as failed"
			error "User reported ${environmentLabel} failure, marking build as failed"
			currentBuild.result = "FAILURE"
		} else {
			currentBuild.result = "SUCCESS"
		}
	}
}

/*
 * Tags the current release as a release candiate
 *
 */
def tagReleaseCandiate(tag) {
	milestone (9)
	try {
		codeGitCheckout()
		dir ('code') {
			withEnv(["FULL_BUILD_VERSION=${this.fullBuildVersion}","APPLICATION=${this.getAppName()}", "TAG=${tag}"]) {
				sh '''
					git reset --hard
					git tag -a "${TAG}/${APPLICATION}/${FULL_BUILD_VERSION}" -m "Release Candidate ${FULL_BUILD_VERSION}"
					git push origin --tags
					'''
			}
		currentBuild.result = "SUCCESS"
		}
	} catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
}

/*
 * Delete a docker environment
 * environment name/type of environment to build the images for
 *
 */
def deleteEnvironment(String environment) {
	doDockerCmdOnEnvironment(environment, "rm -f")
	removeDockerNetwork(environment)
}

/*
 * Stop a docker application environment 
 * environment name/type of environment to build the images for
 *
 */
def stopEnvironment(String environment) {
	doDockerCmdOnEnvironment(environment, "stop")
	removeDockerNetwork(environment)
}

/*
 * Perform a docker command (rm, stop, for example) on an application environment 
 * environment name/type of environment to build the images for
 * cmd command to perform
 *
 */
def doDockerCmdOnEnvironment(String environment, String cmd) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}", "COMMAND=${cmd}"]) {
		sh '''
			#export DOCKER_HOST=tcp://$(hostname -f):2376
			export ENV_NAME=${APPLICATION}-.*-${ENVIRONMENT}
			[ ! -z "$(sudo -E docker ps -qa --filter name=${ENV_NAME})" ] && sudo -E docker ${COMMAND} $(sudo -E docker ps -qa --filter name=${ENV_NAME}) || true
			export ENV_NAME=${APPLICATION}.*${FULL_BUILD_VERSION//\\./-}.*${ENVIRONMENT}
			[ ! -z "$(sudo -E docker ps -qa --filter name=${ENV_NAME})" ] && sudo -E docker ${COMMAND} $(sudo -E docker ps -qa --filter name=${ENV_NAME}) || true						 
		'''
	}
}

/*
 * Remove a docker network based on the version number, and environment
 *
 */
def removeDockerNetwork(String environment) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
		sh '''
			# export DOCKER_HOST=tcp://$(hostname -f):2376
			export NETWORK_NAME=${APPLICATION}${FULL_BUILD_VERSION}${ENVIRONMENT}_common
			sudo -E docker network rm ${NETWORK_NAME} || true
		'''
	}
}

/*
 * Delete "old" docker application environments
 * environment name/type of environment to build the images for
 *
 */
def deleteOldEnvironments(String environment) {
	withEnv(["FULL_BUILD_VERSION=${this.getFullBuildVersion()}", "APPLICATION=${this.getAppName()}", "ENVIRONMENT=${environment}"]) {
		sh '''
			# export DOCKER_HOST=tcp://$(hostname -f):2376
			cd code/environment/deployments/
			sudo bash ./remove-all-old-app-env.sh ${FULL_BUILD_VERSION} ${ENVIRONMENT} ${APPLICATION}
			'''
	}
}

/*
 * Ensure we run the correct version of ruby. Assumes this version is already
 * installed
 */
def withRvm(String version, String gemset, Closure cl) {

	final RVM_HOME = "/usr/local/rvm"
	paths = [
		"$RVM_HOME/gems/ruby-${version}@${gemset}/bin",
		"$RVM_HOME/gems/ruby-${version}@global/bin",
		"$RVM_HOME/rubies/ruby-${version}/bin",
		"$RVM_HOME/bin",
		"${env.PATH}"
		]
		
	def path = paths.join(':')
	withEnv([
		"PATH=${path}",
		"GEM_HOME=${RVM_HOME}/gems/ruby-${version}@${gemset}",
		"GEM_PATH=${RVM_HOME}/gems/ruby-${version}@${gemset}:${RVM_HOME}/gems/${version}@global",
		"MY_RUBY_HOME=${RVM_HOME}/rubies/ruby-${version}",
		"IRBRC=${RVM_HOME}/rubies/ruby-${version}/.irbrc",
		"RUBY_VERSION=${version}",
		"RVM_HOME=${RVM_HOME}",
		"GEMSET=${gemset}"
		]) {
		sh 'bash -c "source ${RVM_HOME}/scripts/rvm; rvm use --create --install --binary ruby-${RUBY_VERSION}@${GEMSET}"'
        cl()
		sh 'bash -c "rvm --force gemset delete ruby-${RUBY_VERSION}@${GEMSET}"'
    }
}

/*
 * Avoid sharing gem directories during build execution and race conditions during resolving dependency
 * so we can easily address that by using one gemset per executor
 */
def withRvm(String version, Closure cl) {
		def buildVersion = getFullBuildVersion()replace(".", "_")
    withRvm(version, "executor-${env.EXECUTOR_NUMBER}-version-${buildVersion}") {
        cl()
    }
}

/*
	* Get whats changed in source control from the current build, and format in a string
	* Format is:
	* 	<author> <timestamp>, <commit-message>:
	*		<file-path> (<change-type>)
	*
	*/
@NonCPS
def getChangeLogAsFormattedString() {
	def changeLog = ""
	def changeLogSets = this.currentBuild.changeSets
	for (int i = 0; i < changeLogSets.size(); i++) {
		def entries = changeLogSets[i].items
		for (int j = 0; j < entries.length; j++) {
			def entry = entries[j]
			changeLog += "\n${entry.author} on ${new Date(entry.timestamp)}, ${entry.msg}: \n"
			def files = new ArrayList(entry.affectedFiles)
			for (int k = 0; k < files.size(); k++) {
				def file = files[k]
				changeLog += "\t${file.path} (${file.editType.name})\n"
			}
		}
	}
	return changeLog
}
