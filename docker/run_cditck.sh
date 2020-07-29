#!/bin/bash -xe
#
# Copyright (c) 2018, 2020 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v. 2.0, which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# This Source Code may also be made available under the following Secondary
# Licenses when the conditions for such availability set forth in the
# Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
# version 2 with the GNU Classpath Exception, which is available at
# https://www.gnu.org/software/classpath/license.html.
#
# SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0

VER=3.0.0

if ls ${WORKSPACE}/bundles/*cdi-tck*.zip 1> /dev/null 2>&1; then
  unzip -o ${WORKSPACE}/bundles/*cdi-tck*.zip -d ${WORKSPACE}
else
  echo "[ERROR] TCK bundle not found"
  exit 1
fi

export TS_HOME=${WORKSPACE}/cdi-tck-glassfish-porting

#Install Glassfish
echo "Download and install GlassFish ..."
wget --progress=bar:force --no-cache $GF_BUNDLE_URL -O ${WORKSPACE}/latest-glassfish.zip
unzip -o ${WORKSPACE}/latest-glassfish.zip -d ${WORKSPACE}

if [ -z "${CDI_TCK_VERSION}" ]; then
  CDI_TCK_VERSION=3.0.0-RC1
fi

if [ -z "${CDI_TCK_BUNDLE_URL}" ]; then
  CDI_TCK_BUNDLE_URL=http://download.eclipse.org/ee4j/cdi/cdi-tck-${CDI_TCK_VERSION}-dist.zip	
fi

rm -fr arquillian-core-master 
wget https://github.com/jakartaredhat/arquillian-core/archive/master.zip -O arquillian-core.zip
unzip -q arquillian-core.zip
cd arquillian-core-master
mvn --global-settings "${TS_HOME}/settings.xml" clean install
cd $WORKSPACE

# Build 1.0.0-SNAPSHOT release of arquillian-container-glassfish6
rm -fr arquillian-container-glassfish6-master 
wget https://github.com/arquillian/arquillian-container-glassfish6/archive/master.zip -O arquillian-container-glassfish6.zip
unzip -q arquillian-container-glassfish6.zip
cd arquillian-container-glassfish6-master
mvn --global-settings "${TS_HOME}/settings.xml" clean install
cd $WORKSPACE

rm -fr glassfish-cdi-porting-tck-master 
wget https://github.com/eclipse-ee4j/glassfish-cdi-porting-tck/archive/master.zip -O glassfish-cdi-porting-tck.zip
unzip -q glassfish-cdi-porting-tck.zip
cd glassfish-cdi-porting-tck-master
mvn --global-settings "${TS_HOME}/settings.xml" clean install
cd $WORKSPACE


#Install CDI TCK dist
echo "Download and unzip CDI TCK dist ..."
wget --progress=bar:force --no-cache $CDI_TCK_BUNDLE_URL -O latest-cdi-tck-dist.zip
unzip -o ${WORKSPACE}/latest-cdi-tck-dist.zip -d ${WORKSPACE}/

GROUP_ID=jakarta.enterprise
CDI_TCK_DIST=cdi-tck-${CDI_TCK_VERSION}

mvn --global-settings "${TS_HOME}/settings.xml" org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
-Dfile=${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-api-${CDI_TCK_VERSION}.jar \
-DgroupId=${GROUP_ID} \
-DartifactId=cdi-tck-api \
-Dversion=${CDI_TCK_VERSION} \
-Dpackaging=jar

mvn --global-settings "${TS_HOME}/settings.xml" org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
-Dfile=${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-impl-${CDI_TCK_VERSION}.jar \
-DgroupId=${GROUP_ID} \
-DartifactId=cdi-tck-impl \
-Dversion=${CDI_TCK_VERSION} \
-Dpackaging=jar

mvn --global-settings "${TS_HOME}/settings.xml" org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
-Dfile=${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-ext-lib-${CDI_TCK_VERSION}.jar \
-DgroupId=${GROUP_ID} \
-DartifactId=cdi-tck-ext-lib \
-Dversion=${CDI_TCK_VERSION} \
-Dpackaging=jar

mvn --global-settings "${TS_HOME}/settings.xml" org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
-Dfile=${WORKSPACE}/${CDI_TCK_DIST}/weld/jboss-tck-runner/src/test/tck20/tck-tests.xml \
-DgroupId=${GROUP_ID} \
-DartifactId=cdi-tck-impl \
-Dversion=${CDI_TCK_VERSION} \
-Dpackaging=xml

mvn --global-settings "${TS_HOME}/settings.xml" org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file \
-Dfile=${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-parent-${CDI_TCK_VERSION}.pom \
-DgroupId=${GROUP_ID} \
-DartifactId=cdi-tck-parent \
-Dversion=${CDI_TCK_VERSION} \
-Dpackaging=pom

which ant
ant -version

if [[ "$JDK" == "JDK11" || "$JDK" == "jdk11" ]];then
  export JAVA_HOME=${JDK11_HOME}
  export PATH=$JAVA_HOME/bin:$PATH
fi

which java
java -version

REPORT=${WORKSPACE}/cdi-tck-report

mkdir -p ${REPORT}/cdi-$VER-sig
mkdir -p ${REPORT}/cdi-$VER

#Edit Glassfish Security policy
cat ${WORKSPACE}/docker/CDI.policy >> ${WORKSPACE}/glassfish6/glassfish/domains/domain1/config/server.policy

#Edit test properties
sed -i "s#porting.home=.*#porting.home=${TS_HOME}#g" ${TS_HOME}/build.properties
sed -i "s#glassfish.home=.*#glassfish.home=${WORKSPACE}/glassfish6/glassfish#g" ${TS_HOME}/build.properties
if [[ "${PROFILE}" == "web" || "${PROFILE}" == "WEB" ]]; then
  sed -i "s#javaee.level=.*#javaee.level=web#g" ${TS_HOME}/build.properties
else
  sed -i "s#javaee.level=.*#javaee.level=full#g" ${TS_HOME}/build.properties
fi
sed -i "s#report.dir=.*#report.dir=${REPORT}#g" ${TS_HOME}/build.properties
sed -i "s#admin.user=.*#admin.user=admin#g" ${TS_HOME}/build.properties
sed -i "s#cdiextjar=.*#cdiextjar=cdi-tck-ext-lib-${CDI_TCK_VERSION}.jar#g" ${TS_HOME}/build.properties
sed -i "s#cdiext.version=.*#cdiext.version=${CDI_TCK_VERSION}#g" ${TS_HOME}/build.properties

cp ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests.xml ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests_bkup.xml 
cp ${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-impl-${CDI_TCK_VERSION}-suite.xml ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests.xml

sed -i "s#<suite name=.*#<suite name=\"CDI TCK\" verbose=\"0\" configfailurepolicy=\"continue\">#g" ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests.xml

#Run Tests
cd ${TS_HOME}
export MAVEN_OPTS="-Duser.home=$HOME $MAVEN_OPTS"
ant $ANT_OPTS sigtest
ant $ANT_OPTS test


#Generate Reports
echo "<pre>" > ${REPORT}/cdi-$VER-sig/report.html
cat $REPORT/cdi_sig_test_results.txt >> $REPORT/cdi-$VER-sig/report.html
echo "</pre>" >> $REPORT/cdi-$VER-sig/report.html
cp $REPORT/cdi-$VER-sig/report.html $REPORT/cdi-$VER-sig/index.html

# Copy the test reports to the report directory
cp -R ${TS_HOME}/glassfish-tck-runner/target/surefire-reports/* ${REPORT}/cdi-${VER}
if [[ -f ${REPORT}/cdi-$VER/test-report.html ]];then
  cp ${REPORT}/cdi-$VER/test-report.html ${REPORT}/cdi-${VER}/report.html
fi

mv ${REPORT}/cdi-$VER/TEST-TestSuite.xml  ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
sed -i 's/name=\"TestSuite\"/name="cditck-3.0"/g' ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
# Create Junit formated file for sigtests
echo '<?xml version="1.0" encoding="UTF-8" ?>' > $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testsuite tests="TOTAL" failures="FAILED" name="cdi-3.0.0-sig" time="0" errors="0" skipped="0">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testcase classname="CDISigTest" name="cdiSigTest" time="0.2">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  <system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
cat $REPORT/cdi_sig_test_results.txt >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  </system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testcase>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testsuite>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml

# Fill appropriate test counts
if [ -f "$REPORT/cdi-$VER-sig/report.html" ]; then
  if grep -q STATUS:Passed "$REPORT/cdi-$VER-sig/report.html"; then
    sed -i 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i 's/failures=\"FAILED\"/failures="0"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  else 
    sed -i 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i 's/failures=\"FAILED\"/failures="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  fi
fi

tar zcvf ${WORKSPACE}/cdi-tck-results.tar.gz ${REPORT} ${WORK}

