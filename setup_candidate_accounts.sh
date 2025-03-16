#!/bin/bash

# Set the template repository URL
TEMPLATE_REPO="https://github.com/anil-learnlytica/panda-assess-march-25-1.git"
TEMPLATE_DIR="template_repo"

# Clone the template repository into a temporary directory
echo "Cloning template repository..."
rm -rf $TEMPLATE_DIR  # Ensure the directory is clean before cloning
git clone --depth=1 $TEMPLATE_REPO $TEMPLATE_DIR

# Verify template repo was cloned successfully
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "❌ Failed to clone the template repository! Exiting..."
    exit 1
fi

# Verify necessary files exist
REQUIRED_FILES=(".github/workflows/grading.yml" "main.py" "test_main.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$TEMPLATE_DIR/$file" ]; then
        echo "❌ Missing required file in template repo: $file"
        rm -rf $TEMPLATE_DIR  # Cleanup before exiting
        exit 1
    fi
done

# Loop through each student in students.txt
while read student; do 
    STUDENT_REPO_NAME="student-$student"

    # Check if the repository already exists
    if gh repo view anil-learnlytica/$STUDENT_REPO_NAME &>/dev/null; then
        echo "⚠️ Repository $STUDENT_REPO_NAME already exists. Skipping creation."
    else
        # Create a public GitHub repository for the student
        echo "Creating repository: $STUDENT_REPO_NAME..."
        gh repo create anil-learnlytica/$STUDENT_REPO_NAME --public -y
    fi

    # Wait for GitHub to make the repo available
    sleep 5  # Delay to allow GitHub to process the repo creation

    # Clone the newly created student repository
    gh repo clone anil-learnlytica/$STUDENT_REPO_NAME
    if [ ! -d "$STUDENT_REPO_NAME" ]; then
        echo "❌ Failed to clone $STUDENT_REPO_NAME. Skipping..."
        continue
    fi

    # Additional delay after cloning to ensure stability
    sleep 5  

    cd $STUDENT_REPO_NAME

    # Create necessary directories
    mkdir -p .github/workflows

    # Copy only the required files from the template repository
    cp ../$TEMPLATE_DIR/.github/workflows/grading.yml .github/workflows/grading.yml
    cp ../$TEMPLATE_DIR/main.py main.py
    cp ../$TEMPLATE_DIR/test_main.py test_main.py

    # Add, commit, and push changes using gh
    gh repo sync anil-learnlytica/$STUDENT_REPO_NAME --force
    gh pr create --title "Initial Setup" --body "Adding template files" --base main --head main
    gh pr merge --auto --delete-branch

    # Move back to the root directory
    cd ..

    echo "✅ Setup completed for: $STUDENT_REPO_NAME"
done < students.txt

# Cleanup: Remove the template repository after processing all students
rm -rf $TEMPLATE_DIR

echo "🎉 All student repositories have been created and initialized successfully!"
