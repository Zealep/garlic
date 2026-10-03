package com.zealep.garlicbackend.compra;

/**
 * Estado del pago de la materia prima al agricultor/proveedor.
 */
public enum EstadoPago {
    /** Aun no hay cargas registradas. */
    SIN_COMPRAS,
    /** Hay cargas y no se ha pagado nada. */
    POR_PAGAR,
    /** Se pago una parte. */
    PARCIAL,
    /** Saldo 0. */
    PAGADO,
    /** Los pagos superan el total (adelanto excedente a regularizar). */
    PAGADO_DE_MAS
}
