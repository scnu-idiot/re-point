package com.idiot.re_point.exchange.controller;

import com.idiot.re_point.exchange.dto.RedeemRequest;
import com.idiot.re_point.exchange.dto.RedeemResponse;
import com.idiot.re_point.exchange.service.ExchangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/exchanges")
@RequiredArgsConstructor
public class ExchangeController {

    private final ExchangeService exchangeService;

    @PostMapping("/redeem/{uid}")
    public ResponseEntity<RedeemResponse> redeem(@PathVariable String uid,
                                                 @RequestBody RedeemRequest req)
            throws ExecutionException, InterruptedException {
        RedeemResponse res = exchangeService.redeem(uid, req.getCardId());
        return ResponseEntity.ok(res);
    }
}