# Extend the maven image in this one.
# The maven image will be pulled remotely if necessary
FROM maven

# Run Maven
# Because we mount the source code at container runtime to /source, we need to get the pom there.
# We are using tika-core's pom.xml to save time by only working with that module.
#ENTRYPOINT ["mvn", "-f", "source/tika-core/pom.xml"]

# The default target for Maven for this project is clean install.
# If we want another target, include when running the container,
# e.g. `docker run tika-container package`
#CMD ["install"]
RUN echo building image
CMD echo image built
