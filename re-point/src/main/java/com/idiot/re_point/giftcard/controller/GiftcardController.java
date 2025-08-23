// com.idiot.re_point.giftcard.controller.GiftcardController.java
package com.idiot.re_point.giftcard.controller;

import com.idiot.re_point.giftcard.dto.GiftcardUpsertRequest;
import com.idiot.re_point.giftcard.model.Giftcard;
import com.idiot.re_point.giftcard.service.GiftcardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/giftcards")
@RequiredArgsConstructor
public class GiftcardController {
    private final GiftcardService giftcardService;

    // 개별 업서트
    @PostMapping("/{cardId}")
    public ResponseEntity<?> upsert(@PathVariable String cardId,
                                    @RequestBody GiftcardUpsertRequest req)
            throws ExecutionException, InterruptedException {
        Giftcard g = Giftcard.builder()
                .cardId(cardId)
                .cardName(req.getCardName())
                .cardValue(req.getCardValue() == null ? 0 : req.getCardValue())
                .stock(req.getStock() == null ? 0 : req.getStock())
                .active(req.getActive() == null || req.getActive()) // 기본 true
                .build();
        giftcardService.upsert(cardId, g);
        return ResponseEntity.ok().body("{\"result\":\"OK\"}");
    }

    // 기본 세트 시드
    @PostMapping("/_seed-defaults")
    public ResponseEntity<?> seed() throws ExecutionException, InterruptedException {
        giftcardService.seedDefaults();
        return ResponseEntity.ok().body("{\"seed\":\"OK\"}");
    }
}