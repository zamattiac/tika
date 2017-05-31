FROM Java:8

# run maven
CMD ["mvn", "clean install"]
CMD ["echo", "Running from container"]
