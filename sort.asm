;
; sort.asm - qsort_asm, a recursive quicksort callable from C.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it does nothing, which makes
; the benchmark print "NOT SORTED" and "Match: NO". Your job is to replace
; that with the sort described below.
;
; The contract, from bench.c:
;
;       int n                     [ebp+12]
;       int *arr                  [ebp+8]
;
; Sort n 32-bit signed integers in place, ascending. This is the C-facing
; routine. It must obey cdecl (prologue, args at [ebp+8]+, return in eax,
; preserve ebx/esi/edi/ebp, clean arguments after every call it makes). The
; manual lets you use any convention you document for the internal recursive
; routine, but the outer one is fixed.
;
; Requirements from the manual:
;
;   * Recursive. An iterative sort with an explicit stack array does not
;     satisfy the activity.
;   * Lomuto partition with the last element as pivot (the manual's scheme).
;   * No calls into the C standard library.
;   * Clean the arguments off the stack after each call. The next pop
;     otherwise loads an argument into a register you promised to
;     preserve, and the outer call's array base is gone.
;
; The manual's pseudocode:
;
;   qsort(arr, lo, hi):
;       if lo >= hi: return
;       p = partition(arr, lo, hi)
;       qsort(arr, lo, p - 1)
;       qsort(arr, p + 1, hi)
;
;   partition(arr, lo, hi):
;       pivot = arr[hi]
;       i = lo - 1
;       for j = lo to hi - 1:
;           if arr[j] <= pivot:
;               i = i + 1
;               swap arr[i], arr[j]
;       swap arr[i + 1], arr[hi]
;       return i + 1
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _qsort_asm qsort_asm
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _qsort_asm
_qsort_asm:
        enter   0,0
        mov     ecx, [ebp+12]           ; n
        cmp     ecx, 1
        jle     .done                   ; signed: n <= 1 is already sorted (covers n = 0)
        dec     ecx                     ; hi = n - 1
        push    ecx                     ; hi
        push    dword 0                 ; lo
        push    dword [ebp+8]           ; arr
        call    qsort_inner
        add     esp, 12                 ; caller cleans its 3 arguments
.done:  leave
        ret

; qsort_inner(arr, lo, hi): same convention as cdecl, args at [ebp+8], [ebp+12], [ebp+16].
qsort_inner:
        enter   0,0
        push    ebx
        push    esi
        push    edi
        mov     esi, [ebp+8]            ; arr
        mov     ebx, [ebp+12]           ; lo
        mov     edi, [ebp+16]           ; hi
        cmp     ebx, edi
        jge     .ret                    ; signed: lo >= hi, nothing to sort

        push    edi                     ; hi
        push    ebx                     ; lo
        push    esi                     ; arr
        call    partition               ; eax = p
        add     esp, 12
        
        push    eax                     ; keep p across the first call (eax is caller-saved)
        lea     ecx, [eax-1]
        push    ecx                     ; hi = p - 1
        push    ebx                     ; lo
        push    esi                     ; arr
        call    qsort_inner
        add     esp, 12
        pop     eax                     ; p
        inc     eax
        push    edi                     ; hi
        push    eax                     ; lo = p + 1
        push    esi                     ; arr
        call    qsort_inner
        add     esp, 12

.ret:   pop     edi
        pop     esi
        pop     ebx
        leave
        ret
; partition(arr, lo, hi) -> eax = final pivot index. Same convention as cdecl.
partition:
        enter   0,0
        push    ebx
        push    esi
        push    edi
        mov     esi, [ebp+8]            ; arr
        mov     ecx, [ebp+12]           ; j = lo
        mov     edi, [ebp+16]           ; hi
        lea     ebx, [ecx-1]            ; i = lo - 1
.loop:  cmp     ecx, edi
        jge     .last
        mov     eax, [esi+ecx*4]        ; arr[j]
        cmp     eax, [esi+edi*4]        ; pivot = arr[hi]; the loop never moves it
        jg      .next                   ; signed: negatives sort correctly
        inc     ebx
        mov     edx, [esi+ebx*4]        ; swap arr[i], arr[j]
        mov     [esi+ebx*4], eax
        mov     [esi+ecx*4], edx
.next:  inc     ecx
        jmp     .loop
.last:  inc     ebx                     ; p = i + 1
        mov     eax, [esi+ebx*4]        ; swap arr[p], arr[hi]
        mov     edx, [esi+edi*4]
        mov     [esi+ebx*4], edx
        mov     [esi+edi*4], eax
        mov     eax, ebx                ; return p
        pop     edi
        pop     esi
        pop     ebx
        leave
        ret