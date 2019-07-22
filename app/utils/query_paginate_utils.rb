# frozen_string_literal: true

module QueryPaginateUtils
  DEFAULT_PAGE_SIZE = 3

  def paginate_query(query, page: 0, page_size: DEFAULT_PAGE_SIZE)
    limit = (page_size || DEFAULT_PAGE_SIZE).to_i
    offset = (page || 0).to_i * DEFAULT_PAGE_SIZE

    query.offset(offset).limit(limit)
  end
end
