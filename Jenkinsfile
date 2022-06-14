/*
 * Copyright (c) 2018, 2022 Oracle and/or its affiliates. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0, which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the
 * Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
 * version 2 with the GNU Classpath Exception, which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 */

env.label = "cdi-tck-ci-pod-${UUID.randomUUID().toString()}"
pipeline {
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  agent {
    kubernetes {
      label "${env.label}"
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
spec:
  hostAliases:
  - ip: "127.0.0.1"
    hostnames:
    - "localhost.localdomain"
  containers:
  - name: cdi-tck-ci
    image: jakartaee/cts-base:0.3
    command:
    - cat
    tty: true
    imagePullPolicy: Always
    env:
      - name: JAVA_TOOL_OPTIONS
        value: -Xmx2G
    resources:
      limits:
        memory: "6Gi"
        cpu: "1.25"
"""
    }
  }
  parameters {
    string(name: 'GF_BUNDLE_URL', 
           defaultValue: 'https://download.eclipse.org/ee4j/glassfish/glassfish-7.0.0-SNAPSHOT-nightly.zip',
           description: 'URL required for downloading GlassFish Full/Web profile bundle' )
    choice(name: 'PROFILE', choices: 'FULL\nWEB', 
           description: 'Profile to be used for running CTS either web/full' )
    choice(name: 'JDK', choices: 'JDK11\nJDK17',
           description: 'Java SE Version to be used for running TCK either JDK11/JDK17' )
	  string(name: 'TCK_BUNDLE_FILE_NAME', 
           defaultValue: '', 
	         description: 'Name of bundle file to be appended to the base url' )
	  string(name: 'CDI_TCK_BUNDLE_URL', 
          defaultValue: 'https://download.eclipse.org/ee4j/cdi/4.0/cdi-tck-4.0.5-dist.zip', 
  	      description: 'CDI TCK bundle url' )
    string(name: 'CDI_TCK_VERSION', 
          defaultValue: '4.0.5', 
          description: 'version of bundle file' )
    string(name: 'TCK_BUNDLE_BASE_URL', 
          defaultValue: '', 
          description: 'url of porting kit bundle file' )
  }
  environment {
    ANT_HOME = "/usr/share/ant"
    MAVEN_HOME = "/usr/share/maven"
    ANT_OPTS = "-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalSchema=all -Djavax.xml.accessExternalDTD=file,http -Duser.home=$HOME"
	MAVEN_OPTS="-Duser.home=$HOME"
  }
  stages {
    stage('cdi-tck-build') {
      steps {
        container('cdi-tck-ci') {
          sh """
            env
            bash -x ${WORKSPACE}/docker/build_cditck.sh
          """
          archiveArtifacts artifacts: 'bundles/*.zip'
        }
      }
    }
  
    stage('cdi-tck-run') {
      steps {
        container('cdi-tck-ci') {
          sh """
            env
            bash -x ${WORKSPACE}/docker/run_cditck.sh
          """
          archiveArtifacts artifacts: "cdi-tck-results.tar.gz,cdi-tck-report/**/*.xml,cdi-tck-report/**/*.html,**/*.*log*"
          junit testResults: 'cdi-tck-report/**/*.xml', allowEmptyResults: true
        }
      }
    }
  }
}
