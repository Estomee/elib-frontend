// Singleton service for user library operations: load books, add/remove from library, and update reading progress.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    function loadUserBooks(userId, pagination, onSuccess, onError) {
        const q = `
            query UserBooks($userId: Int!, $pagination: PaginationInput!) {
                user_books(user_id: $userId, pagination: $pagination) {
                    nodes {
                        user_book_id
                        status
                        last_read_page
                        added_at
                        book {
                            book_id
                            title
                            description
                            page_count
                            year_of_publishing
                            book_cover { file_path storage_key }
                            authors { author_id first_name last_name }
                            genres  { genre_id genre_name }
                            publisher { publisher_id name }
                            language  { lang_id lang_name lang_code }
                        }
                    }
                    total_count
                    page_info { has_next_page end_cursor }
                }
            }
        `
        GraphQLClient.execute(q, { userId: parseInt(userId) || 0, pagination: pagination },
            function(data) { if (onSuccess) onSuccess(data.user_books) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function addBookToLibrary(bookId, onSuccess, onError) {
        const q = `
            mutation AddBookToLibrary($input: AddBookToLibraryInput!) {
                add_book_to_library(input: $input) {
                    id
                    status
                    is_new
                }
            }
        `
        GraphQLClient.execute(q, { input: { book_id: parseInt(bookId) } },
            function(data) { if (onSuccess) onSuccess(data.add_book_to_library) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function removeBookFromLibrary(userBookId, onSuccess, onError) {
        const q = `
            mutation RemoveBookFromLibrary($userBookId: Int!) {
                remove_book_from_library(user_book_id: $userBookId)
            }
        `
        GraphQLClient.execute(q, { userBookId: parseInt(userBookId) },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function updateReadingProgress(userBookId, lastReadPage, onSuccess, onError) {
        const q = `
            mutation UpdateReadingProgress($input: ReadingProgressInput!) {
                update_reading_progress(input: $input) {
                    status
                    last_read_page
                }
            }
        `
        GraphQLClient.execute(q, { input: { user_book_id: parseInt(userBookId), last_read_page: lastReadPage } },
            function(data) { if (onSuccess) onSuccess(data.update_reading_progress) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }
}
