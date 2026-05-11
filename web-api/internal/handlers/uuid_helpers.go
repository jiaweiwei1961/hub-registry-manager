package handlers

import (
	"github.com/google/uuid"
)

// UUIDPtrToString safely converts *uuid.UUID to string, returning empty string if nil
func UUIDPtrToString(id *uuid.UUID) string {
	if id == nil {
		return ""
	}
	return id.String()
}

// UUIDPtrToUUID safely converts *uuid.UUID to uuid.UUID, returning uuid.Nil if nil
func UUIDPtrToUUID(id *uuid.UUID) uuid.UUID {
	if id == nil {
		return uuid.Nil
	}
	return *id
}

// UUIDPtrIsNil checks if *uuid.UUID is nil or points to uuid.Nil
func UUIDPtrIsNil(id *uuid.UUID) bool {
	return id == nil || *id == uuid.Nil
}

// UUIDToPtr converts uuid.UUID to *uuid.UUID
func UUIDToPtr(id uuid.UUID) *uuid.UUID {
	if id == uuid.Nil {
		return nil
	}
	return &id
}

// ParseUUIDToPtr parses string to *uuid.UUID, returns nil if parse fails or empty
func ParseUUIDToPtr(s string) *uuid.UUID {
	if s == "" {
		return nil
	}
	id, err := uuid.Parse(s)
	if err != nil {
		return nil
	}
	if id == uuid.Nil {
		return nil
	}
	return &id
}