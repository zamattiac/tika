# This Dockerfile assumes the workspace is mounted as /source
# Performs no build, Maven must be called as a build step.

# Extend the maven image in this one.
# The maven image will be pulled remotely if necessary
FROM maven

ENTRYPOINT ["echo", "Inside the container"]
