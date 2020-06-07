; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -instcombine  -S < %s | FileCheck %s

declare i32 @memcmp(i8 addrspace(1)* nocapture, i8* nocapture, i64)

define i32 @memcmp_const_size_update_deref(i8 addrspace(1)* nocapture readonly %d, i8* nocapture readonly %s) {
; CHECK-LABEL: @memcmp_const_size_update_deref(
; CHECK-NEXT:    [[CALL:%.*]] = tail call i32 @memcmp(i8 addrspace(1)* dereferenceable(16) dereferenceable_or_null(40) [[D:%.*]], i8* nonnull dereferenceable(16) [[S:%.*]], i64 16)
; CHECK-NEXT:    ret i32 [[CALL]]
;
  %call = tail call i32 @memcmp(i8 addrspace(1)* dereferenceable_or_null(40) %d, i8* %s, i64 16)
  ret i32 %call
}

define i32 @memcmp_nonconst_size_nonnnull(i8 addrspace(1)* nocapture readonly %d, i8* nocapture readonly %s, i64 %n) {
; CHECK-LABEL: @memcmp_nonconst_size_nonnnull(
; CHECK-NEXT:    [[CALL:%.*]] = tail call i32 @memcmp(i8 addrspace(1)* nonnull dereferenceable_or_null(40) [[D:%.*]], i8* nonnull [[S:%.*]], i64 [[N:%.*]])
; CHECK-NEXT:    ret i32 [[CALL]]
;
  %call = tail call i32 @memcmp(i8 addrspace(1)* nonnull dereferenceable_or_null(40) %d, i8* nonnull %s, i64 %n)
  ret i32 %call
}
