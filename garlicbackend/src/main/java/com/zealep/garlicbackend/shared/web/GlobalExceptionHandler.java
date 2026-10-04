package com.zealep.garlicbackend.shared.web;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.EmpresaNoPermitidaException;
import com.zealep.garlicbackend.shared.tenant.TenantRequiredException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.NestedExceptionUtils;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.core.PropertyReferenceException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Traduce excepciones a respuestas RFC 9457 (application/problem+json).
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private static final String SQL_UNIQUE_VIOLATION = "23505";
    private static final String SQL_FK_VIOLATION = "23503";
    private static final String SQL_CHECK_VIOLATION = "23514";

    @ExceptionHandler(NotFoundException.class)
    ProblemDetail handleNotFound(NotFoundException ex) {
        return problem(HttpStatus.NOT_FOUND, "Recurso no encontrado", ex.getMessage());
    }

    @ExceptionHandler(ConflictException.class)
    ProblemDetail handleConflict(ConflictException ex) {
        return problem(HttpStatus.CONFLICT, "Conflicto", ex.getMessage());
    }

    @ExceptionHandler(BusinessException.class)
    ProblemDetail handleBusiness(BusinessException ex) {
        return problem(HttpStatus.UNPROCESSABLE_CONTENT, "Regla de negocio", ex.getMessage());
    }

    @ExceptionHandler(TenantRequiredException.class)
    ProblemDetail handleTenant(TenantRequiredException ex) {
        return problem(HttpStatus.BAD_REQUEST, "Empresa no indicada", ex.getMessage());
    }

    @ExceptionHandler(EmpresaNoPermitidaException.class)
    ProblemDetail handleEmpresaNoPermitida(EmpresaNoPermitidaException ex) {
        return problem(HttpStatus.FORBIDDEN, "Empresa no permitida", ex.getMessage());
    }

    @ExceptionHandler(PropertyReferenceException.class)
    ProblemDetail handlePropertyReference(PropertyReferenceException ex) {
        return problem(HttpStatus.BAD_REQUEST, "Parametro invalido", "Propiedad de ordenamiento invalida: " + ex.getPropertyName());
    }

    /**
     * Red de seguridad de las restricciones de la base (UNIQUE, FK, CHECK).
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    ProblemDetail handleDataIntegrity(DataIntegrityViolationException ex) {
        Throwable cause = NestedExceptionUtils.getMostSpecificCause(ex);
        String sqlState = cause instanceof SQLException sql ? sql.getSQLState() : null;
        String constraint = constraintName(cause);
        logger.debug("Violacion de integridad [{}] {}", sqlState, constraint);

        ProblemDetail pd;
        if (SQL_UNIQUE_VIOLATION.equals(sqlState)) {
            pd = problem(HttpStatus.CONFLICT, "Registro duplicado", "Ya existe un registro con los mismos datos unicos (codigo/nombre)");
        } else if (SQL_FK_VIOLATION.equals(sqlState)) {
            pd = problem(HttpStatus.UNPROCESSABLE_CONTENT, "Referencia invalida", "Alguna referencia (id) no existe o esta en uso");
        } else if (SQL_CHECK_VIOLATION.equals(sqlState)) {
            pd = problem(HttpStatus.UNPROCESSABLE_CONTENT, "Dato invalido", "Algun valor no cumple las reglas de la base de datos");
        } else {
            logger.error("Error de integridad no clasificado", ex);
            pd = problem(HttpStatus.CONFLICT, "Error de integridad", "No se pudo guardar el registro");
        }
        if (constraint != null) {
            pd.setProperty("constraint", constraint);
        }
        return pd;
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        List<Map<String, Object>> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> Map.<String, Object>of(
                        "field", fe.getField(),
                        "message", fe.getDefaultMessage() == null ? "invalido" : fe.getDefaultMessage()))
                .toList();
        ProblemDetail pd = problem(HttpStatus.BAD_REQUEST, "Datos invalidos", "La solicitud tiene campos invalidos");
        pd.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(pd);
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(Exception ex) {
        logger.error("Error no controlado", ex);
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno", "Ocurrio un error inesperado");
    }

    private static ProblemDetail problem(HttpStatus status, String title, String detail) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(status, detail);
        pd.setTitle(title);
        return pd;
    }

    private static String constraintName(Throwable cause) {
        if (cause instanceof org.postgresql.util.PSQLException psql && psql.getServerErrorMessage() != null) {
            return psql.getServerErrorMessage().getConstraint();
        }
        return null;
    }
}
