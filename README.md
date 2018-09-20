----------------------------------------------------------------------
To run the CDI 2.0.x TCK against Glassfish 5.0,
follow the steps in this file. The ant targets provided will call Maven which
will download the TCK artifacts and execute the TCK against the Java EE
Reference implementation.

NOTE:  For the latest CDI TCK Documentation and instructions on how to configure
the TCK to run against a different implementation, please see
http://docs.jboss.org/cdi/tck/reference/2.0.0.Final/en-US/html_single/
----------------------------------------------------------------------

Other links:
=============
TCK Bundle:  http://sourceforge.net/projects/jboss/files/CDI-TCK/2.0.0.Final/
TCK workspace:  https://github.com/jboss/cdi-tck

----------------------------------------------------------------------
Steps to run the tests
=======================
- Install Maven - http://maven.apache.org/download.cgi
  Ensure that mvn is in your path
  Set MAVEN_HOME in your environment

- Install Ant - Use Apache Ant packaged with Java EE CTS bundle available at "javaeetck/tools/ant", 
  Alternatively download it from http://ant.apache.org/bindownload.cgi
  Ensure that ant is in your path

- Install Glassfish V5.0 refer to this as GF_HOME

- Unzip the CDI porting bundle in the top level of the CDI TCK (not required).
    Refer to this location as PORTING_HOME

- cd to PORTING_HOME and edit the build.properties file

- set the JAVA_HOME environment variable in your shell environment

- set porting.home, and glassfish.home in build.properties

- If running against a JavaEE Web Profile Impl which does not support ear files,
  Edit the $PORTING_HOME/build.properties and set javaee.level=web

- If necessary, modify the following default property values in build.xml for your environment
    <property name="max.heap.size" value="3072m" />
    <property name="max.perm.gen.size" value="1024m" />
    On windows, try setting max.heap.size=1024 and max.perm.gen.size=512

- Invoke ant sigtest to run the signature tests

- Invoke 'ant test' to run the TestNG test suite

- To run the sig tests and the TestNG tests in a single run, you can invoke
  ant run.all.tests

- If running Glassfish with a security manager (by executing
  $GF_HOME/bin/asadmin create-jvm-options -Djava.security.manager, you must add
  the following permissions to the server.policy file...

grant {
   permission java.lang.reflect.ReflectPermission "suppressAccessChecks";
   permission org.osgi.framework.AdminPermission "*", "*";
   permission java.lang.RuntimePermission "createClassLoader";
   permission javax.security.auth.AuthPermission "modifyPrincipals";
   permission java.io.SerializablePermission "enableSubclassImplementation";
   permission java.lang.RuntimePermission "accessClassInPackage.com.sun.proxy";
  };
