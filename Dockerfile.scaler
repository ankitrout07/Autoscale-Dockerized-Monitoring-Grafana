FROM docker:latest

# Install dependencies
RUN apk add --no-cache curl jq bc bash

# Set working directory
WORKDIR /app

# Copy the scaler script
COPY scaler.sh .

# Make the script executable
RUN chmod +x scaler.sh

# Run the script
CMD ["./scaler.sh"]
