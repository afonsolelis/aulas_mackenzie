export const grains = Object.freeze({
  day: "date_trunc('day', order_delivered_customer_date)",
  week: "date_trunc('week', order_delivered_customer_date)",
  month: "date_trunc('month', order_delivered_customer_date)"
});

export function evolutionQuery(grain, maxRows) {
  return {
    text: `SELECT ${grains[grain]}::date AS period, COUNT(*)::int AS value
      FROM public.olist_orders
      WHERE order_status = $1 AND order_delivered_customer_date IS NOT NULL
      GROUP BY 1 ORDER BY 1 LIMIT $2`,
    values: ['delivered', maxRows]
  };
}

export function distributionQuery(maxRows) {
  return {
    text: `SELECT price::float AS price
      FROM public.olist_order_items
      WHERE price IS NOT NULL AND price >= $1
      ORDER BY order_id, order_item_id LIMIT $2`,
    values: [0, maxRows]
  };
}

export function magnitudeQuery(top) {
  return {
    text: `SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'sem_categoria') AS category,
        ROUND(SUM(i.price)::numeric, 2)::float AS value
      FROM public.olist_order_items i
      JOIN public.olist_products p ON p.product_id = i.product_id
      LEFT JOIN public.product_category_name_translation t
        ON t.product_category_name = p.product_category_name
      GROUP BY 1 ORDER BY value DESC LIMIT $1`,
    values: [top]
  };
}

export function relationQuery(limit) {
  return {
    text: `SELECT price::float AS price, freight_value::float AS freight
      FROM public.olist_order_items
      WHERE price IS NOT NULL AND freight_value IS NOT NULL
      ORDER BY order_id, order_item_id LIMIT $1`,
    values: [limit]
  };
}
