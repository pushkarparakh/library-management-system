#!/bin/bash

# Database files
BOOK_DB="books.txt"
ISSUED_DB="issued_books.txt"

# Create database files if they don't exist
touch "$BOOK_DB" "$ISSUED_DB"

# Function to display the main menu
main_menu() {
    clear
    echo "====================================="
    echo "    LIBRARY MANAGEMENT SYSTEM        "
    echo "====================================="
    echo "1. Search Books"
    echo "2. Issue a Book"
    echo "3. View Issued Books"
    echo "4. Exit"
    echo "====================================="
    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1) search_books ;;
        2) issue_book ;;
        3) view_issued_books ;;
        4) exit 0 ;;
        *) echo "Invalid choice. Please try again." 
           sleep 1
           main_menu ;;
    esac
}

# Function to search books
search_books() {
    clear
    echo "====================================="
    echo "          SEARCH BOOKS               "
    echo "====================================="
    read -p "Enter book title or author to search (leave empty to see all): " search_term

    if [ -z "$search_term" ]; then
        # Show all books if search term is empty
        echo -e "\nAll Available Books:"
        echo "ID | Title | Author | Copies Available"
        echo "-------------------------------------"
        awk -F: '{printf "%3s | %-20s | %-15s | %2d\n", $1, $2, $3, $4}' "$BOOK_DB"
    else
        # Search for books matching the term (case insensitive)
        echo -e "\nSearch Results for \"$search_term\":"
        echo "ID | Title | Author | Copies Available"
        echo "-------------------------------------"
        grep -i "$search_term" "$BOOK_DB" | awk -F: '{printf "%3s | %-20s | %-15s | %2d\n", $1, $2, $3, $4}'
    fi

    echo -e "\nPress any key to return to main menu..."
    read -n 1 -s
    main_menu
}

# Function to issue a book
issue_book() {
    clear
    echo "====================================="
    echo "           ISSUE A BOOK              "
    echo "====================================="
    
    # Show available books
    echo -e "\nAvailable Books:"
    echo "ID | Title | Author | Copies Available"
    echo "-------------------------------------"
    awk -F: '{if ($4 > 0) printf "%3s | %-20s | %-15s | %2d\n", $1, $2, $3, $4}' "$BOOK_DB"
    
    echo -e "\nEnter details to issue a book:"
    read -p "Book ID: " book_id
    read -p "Your Name: " user_name
    
    # Check if book exists and is available
    book_info=$(grep "^$book_id:" "$BOOK_DB")
    if [ -z "$book_info" ]; then
        echo "Error: Book ID $book_id does not exist."
        sleep 2
        issue_book
        return
    fi
    
    available_copies=$(echo "$book_info" | cut -d: -f4)
    if [ "$available_copies" -le 0 ]; then
        echo "Error: No copies available for this book."
        sleep 2
        issue_book
        return
    fi
    
    # Get book details
    book_title=$(echo "$book_info" | cut -d: -f2)
    book_author=$(echo "$book_info" | cut -d: -f3)
    
    # Decrement available copies in book database
    awk -v id="$book_id" -F: '{
        if ($1 == id) {
            $4 = $4 - 1
        }
        printf "%s:%s:%s:%s\n", $1, $2, $3, $4
    }' "$BOOK_DB" > temp.txt && mv temp.txt "$BOOK_DB"
    
    # Add to issued books database
    issue_date=$(date +"%Y-%m-%d")
    echo "$book_id:$book_title:$book_author:$user_name:$issue_date" >> "$ISSUED_DB"
    
    echo -e "\nBook issued successfully!"
    echo "-------------------------------------"
    echo "Book: $book_title"
    echo "Author: $book_author"
    echo "Issued to: $user_name"
    echo "Date: $issue_date"
    echo "-------------------------------------"
    
    echo -e "\nPress any key to return to main menu..."
    read -n 1 -s
    main_menu
}

# Function to view issued books
view_issued_books() {
    clear
    echo "====================================="
    echo "        CURRENTLY ISSUED BOOKS       "
    echo "====================================="
    
    if [ ! -s "$ISSUED_DB" ]; then
        echo "No books are currently issued."
    else
       echo "ID | Title | Author | Issued To | Date"
        echo "-------------------------------------"
        awk -F: '{printf "%3s | %-15s | %-10s | %-10s | %s\n", $1, $2, $3, $4, $5}' "$ISSUED_DB"
    fi
    
    echo -e "\nPress any key to return to main menu..."
    read -n 1 -s
    main_menu
}

# Initialize with some sample books if the database is empty
initialize_books() {
    if [ ! -s "$BOOK_DB" ]; then
        echo "1:The Great Gatsby:F. Scott Fitzgerald:3" >> "$BOOK_DB"
        echo "2:To Kill a Mockingbird:Harper Lee:2" >> "$BOOK_DB"
        echo "3:1984:George Orwell:5" >> "$BOOK_DB"
        echo "4:Pride and Prejudice:Jane Austen:1" >> "$BOOK_DB"
        echo "5:The Hobbit:J.R.R. Tolkien:4" >> "$BOOK_DB"
    fi
}

# Start the program
initialize_books
main_menu 
