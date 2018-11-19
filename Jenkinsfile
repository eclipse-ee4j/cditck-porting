/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
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
    image: anajosep/cts-base:0.1
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
           defaultValue: 'https://repo1.maven.org/maven2/org/glassfish/main/distributions/glassfish/5.1.0-RC1/glassfish-5.1.0-RC1.zip',
           description: 'URL required for downloading GlassFish Full/Web profile bundle' )
  }
  environment {
    JAVA_HOME = "/opt/jdk1.8.0_171/"
    ANT_HOME = "/usr/share/ant"
    MAVEN_HOME = "/usr/share/maven"
    PATH = "${MAVEN_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
    ANT_OPTS = "-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalSchema=all -Djavax.xml.accessExternalDTD=file,http" 
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
          archiveArtifacts artifacts: "cdi-tck-results.tar.gz"
          junit testResults: 'cdi-tck-report/cdi-2.0/*.xml', allowEmptyResults: true
        }
      }
    }
  }
}
