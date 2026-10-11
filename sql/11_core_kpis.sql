-- ============================================================
-- Core E-commerce KPIs
--
-- Source grain:
-- analytics.fact_orders = one row per order
--
-- Primary commercial population:
-- delivered orders
--
-- Metric definitions:
--
-- Merchandise Value
--   = value of products only
--
-- Freight Charged
--   = freight amount recorded on order items
--   = NOT actual shipping cost or profit
--
-- Checkout Value
--   = merchandise value + freight charged
--
-- Payment Value
--   = amount recorded in payment records
--   = kept separate because it does not always reconcile
--     exactly with merchandise + freight
--
-- Profit / Margin
--   = NOT available from this dataset because product cost,
--     actual shipping cost, commission, and refund accounting
--     are not fully available.
-- ============================================================


SELECT

    -- --------------------------------------------------------
    -- Order volume
    -- --------------------------------------------------------

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'canceled'
    ) AS canceled_orders,


    -- --------------------------------------------------------
    -- Delivered merchandise
    -- Product value only; freight is excluded.
    -- --------------------------------------------------------

    ROUND(
        SUM(item_value) FILTER (
            WHERE order_status = 'delivered'
        ),
        2
    ) AS delivered_merchandise_value,


    -- --------------------------------------------------------
    -- Freight charged
    -- Kept separate from merchandise value.
    -- --------------------------------------------------------

    ROUND(
        SUM(freight_value) FILTER (
            WHERE order_status = 'delivered'
        ),
        2
    ) AS delivered_freight_charged,


    -- --------------------------------------------------------
    -- Checkout value
    -- Merchandise + freight charged.
    -- This is NOT profit.
    -- --------------------------------------------------------

    ROUND(
        SUM(item_plus_freight_value) FILTER (
            WHERE order_status = 'delivered'
        ),
        2
    ) AS delivered_checkout_value,


    -- --------------------------------------------------------
    -- Recorded payment value
    -- Kept as a separate source measure because payment totals
    -- do not reconcile perfectly with item + freight totals.
    -- --------------------------------------------------------

    ROUND(
        SUM(payment_value) FILTER (
            WHERE order_status = 'delivered'
        ),
        2
    ) AS delivered_recorded_payment_value,


    -- --------------------------------------------------------
    -- Primary AOV
    --
    -- Average merchandise value per delivered order.
    -- Freight is intentionally excluded.
    -- --------------------------------------------------------

    ROUND(
        (
            SUM(item_value) FILTER (
                WHERE order_status = 'delivered'
            )
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE order_status = 'delivered'
                ),
                0
            )
        ),
        2
    ) AS delivered_merchandise_aov,


    -- --------------------------------------------------------
    -- Secondary AOV
    --
    -- Average checkout amount represented by
    -- merchandise + freight.
    -- --------------------------------------------------------

    ROUND(
        (
            SUM(item_plus_freight_value) FILTER (
                WHERE order_status = 'delivered'
            )
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE order_status = 'delivered'
                ),
                0
            )
        ),
        2
    ) AS delivered_checkout_aov,


    -- --------------------------------------------------------
    -- Cancellation rate
    --
    -- Share of all placed orders that were canceled.
    -- --------------------------------------------------------

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'canceled'
        )::numeric
        /
        NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS cancellation_rate_pct

FROM analytics.fact_orders;