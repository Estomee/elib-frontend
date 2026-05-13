// Singleton service for book-related GraphQL operations: CRUD, file URLs, and reference data queries.
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
                        isbn
                        year_of_publishing
                        page_count
                        edition_number
                        book_cover    { storage_key file_path }
                        book_content  { storage_key file_name mime_type file_size }
                        authors { author_id first_name last_name }
                        genres  { genre_id genre_name }
                        language { lang_id lang_name lang_code }
                        type_of_work { work_id type_name }
                        publisher { publisher_id name }
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
        GraphQLClient.execute(q, { pagination: pagination, filter: filter || null },
            function(data) { if (onSuccess) onSuccess(data.load_books) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function getBook(bookId, onSuccess, onError) {
        const q = `
            query GetBook($id: Int!) {
                book(id: $id) {
                    book_id
                    title
                    description
                    isbn
                    year_of_publishing
                    page_count
                    edition_number
                    book_cover  { file_path storage_key }
                    book_file   { file_path storage_key mime_type }
                    authors     { author_id first_name last_name }
                    genres      { genre_id genre_name }
                    language    { lang_id lang_name lang_code }
                    type_of_work { work_id type_name }
                    publisher   { publisher_id name }
                }
            }
        `
        GraphQLClient.execute(q, { id: parseInt(bookId) },
            function(data) { if (onSuccess) onSuccess(data.book) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function getBookFileUrl(bookId, onSuccess, onError) {
        const q = `
            query BookFileUrl($bookId: Int!) {
                book_file_url(book_id: $bookId)
            }
        `
        GraphQLClient.execute(q, { bookId: parseInt(bookId) },
            function(data) { if (onSuccess) onSuccess(data.book_file_url) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function getUploadUrl(contentType, onSuccess, onError) {
        const q = `
            mutation GetUploadUrl($content_type: String!) {
                get_upload_url(content_type: $content_type) {
                    presigned_url
                    storage_key
                }
            }
        `
        GraphQLClient.execute(q, { content_type: contentType },
            function(data) { if (onSuccess) onSuccess(data.get_upload_url) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function createBook(input, onSuccess, onError) {
        const q = `
            mutation CreateBook($input: CreateBookInput!) {
                create_book(input: $input) {
                    book_id
                    title
                }
            }
        `
        GraphQLClient.execute(q, { input: input },
            function(data) { if (onSuccess) onSuccess(data.create_book) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function updateBook(bookId, input, onSuccess, onError) {
        const q = `
            mutation UpdateBook($input: UpdateBookInput!) {
                update_book(input: $input) {
                    book_id
                    title
                }
            }
        `
        GraphQLClient.execute(q, { input: input },
            function(data) { if (onSuccess) onSuccess(data.update_book) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function deleteBook(bookId, onSuccess, onError) {
        const q = `
            mutation DeleteBook($book_id: Int!) {
                delete_book(book_id: $book_id)
            }
        `
        GraphQLClient.execute(q, { book_id: parseInt(bookId) },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadAuthors(onSuccess, onError) {
        const q = `
            query Authors {
                authors { author_id first_name last_name }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.authors) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadGenres(onSuccess, onError) {
        const q = `
            query Genres {
                genres { genre_id genre_name parent_genre_id }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.genres) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function getBookCoverUrl(bookId, onSuccess, onError) {
        const q = `
            query BookCoverUrl($bookId: Int!) {
                book_cover_url(book_id: $bookId)
            }
        `
        GraphQLClient.execute(q, { bookId: parseInt(bookId) },
            function(data) { if (onSuccess) onSuccess(data.book_cover_url) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadLanguages(onSuccess, onError) {
        const q = `
            query Languages {
                languages { lang_id lang_name lang_code }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.languages) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadPublishers(onSuccess, onError) {
        const q = `
            query Publishers {
                publishers { publisher_id name }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.publishers) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadTypesOfWork(onSuccess, onError) {
        const q = `
            query TypesOfWork {
                types_of_work { work_id type_name }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.types_of_work) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }
}
