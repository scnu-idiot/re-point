package com.idiot.re_point.giftcard.controller;

import com.idiot.re_point.giftcard.dto.GiftcardDto;
import com.idiot.re_point.giftcard.model.GiftCardTransaction;
import com.idiot.re_point.giftcard.service.GiftcardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/giftcards")
@RequiredArgsConstructor
public class GiftcardController {

    private final GiftcardService giftcardService;

    @GetMapping
    public ResponseEntity<List<GiftcardDto>> listActive()
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(giftcardService.listActive());
    }

    @GetMapping("/{uid}/history")
    public ResponseEntity<List<GiftCardTransaction>> listTransactions(@PathVariable String uid)
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(giftcardService.listTransactions(uid));
    }
}