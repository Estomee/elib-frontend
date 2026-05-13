// Singleton service for the public book catalog: paginated book listing and add-to-library mutation.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    function loadBooks(pagination, filter, onSuccess, onError) {
        const q = `
            query LoadBooks($pagination: PaginationInput!, $filter: BookFilter) {
                load_books(pagination: $pagination, filter: $filter) {
                    nodes {
                        book_id
                        title
                        description
                        year_of_publishing
                        book_cover { file_path storage_key }
                        authors { first_name last_name }
                        genres  { genre_id genre_name }
                        language { lang_name }
                        type_of_work { type_name }
                        publisher { name }
                    }
                    total_count
                    page_info {
                        has_next_page
                        has_previous_page
                        start_cursor
                        end_cursor
                    }
                }
            }
        `
        GraphQLClient.execute(q, { pagination: pagination, filter: filter || {} },
            function(data) { if (onSuccess) onSuccess(data.load_books) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function addToLibrary(bookId, onSuccess, onError) {
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
}
