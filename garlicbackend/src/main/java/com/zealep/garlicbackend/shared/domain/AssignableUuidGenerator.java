package com.zealep.garlicbackend.shared.domain;

import java.util.EnumSet;
import java.util.UUID;
import org.hibernate.engine.spi.SharedSessionContractImplementor;
import org.hibernate.generator.BeforeExecutionGenerator;
import org.hibernate.generator.EventType;
import org.hibernate.generator.EventTypeSets;

/**
 * Ver {@link AssignableUuid}.
 */
public class AssignableUuidGenerator implements BeforeExecutionGenerator {

    @Override
    public Object generate(SharedSessionContractImplementor session, Object owner, Object currentValue, EventType eventType) {
        return currentValue != null ? currentValue : UUID.randomUUID();
    }

    @Override
    public EnumSet<EventType> getEventTypes() {
        return EventTypeSets.INSERT_ONLY;
    }

    @Override
    public boolean allowAssignedIdentifiers() {
        return true;
    }
}
